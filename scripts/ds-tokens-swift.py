#!/usr/bin/env python3
"""Generate the iOS design tokens from the vendored design system.

Reads   design-system/tokens.json            (the only source of values)
        design-system/README.md              (the "Dynamic Type" table: step -> iOS text style)
        apps/ios/NomNom/Core/Fonts/*.ttf     (PostScript names of the bundled font files)
Writes  apps/ios/NomNom/Core/Design/Generated/DSTokens.generated.swift

Deterministic and idempotent: the same inputs always produce byte-identical
output. Standard library only. Run from anywhere:

    python3 scripts/ds-tokens-swift.py

Every token family in tokens.json is emitted. An unknown family, an
unresolvable alias or a type style that does not land on a `text-*` /
`leading-*` step is an error, never a guess.
"""
import json
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DS_DIR = os.path.join(ROOT, "design-system")
TOKENS = os.path.join(DS_DIR, "tokens.json")
README = os.path.join(DS_DIR, "README.md")
VERSION = os.path.join(DS_DIR, "VERSION")
FONTS_DIR = os.path.join(ROOT, "apps", "ios", "NomNom", "Core", "Fonts")
OUT = os.path.join(ROOT, "apps", "ios", "NomNom", "Core", "Design", "Generated",
                   "DSTokens.generated.swift")

PT_PER_REM = 16.0

# Families this generator knows how to emit. Anything else in tokens.json fails the run.
KNOWN_FAMILIES = {
    "version", "name", "meta", "color", "type", "spacing", "radius", "shadow", "opacity",
    "container", "text", "font-weight", "tracking", "leading", "border-width", "motion",
}

# iOS text styles accepted from the README's Dynamic Type table.
SWIFT_TEXT_STYLES = {
    "largeTitle", "title", "title2", "title3", "headline", "subheadline",
    "body", "callout", "footnote", "caption", "caption2",
}


def fail(msg):
    print("ds-tokens-swift: error: " + msg, file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------- naming

def camel(parts):
    parts = [p for p in parts if p]
    out = parts[0].lower()
    for p in parts[1:]:
        out += p[:1].upper() + p[1:]
    return out


def size_word(word):
    """Tailwind size words that start with a digit: `2xl` -> `xl2`, `2xs` -> `xs2`."""
    m = re.fullmatch(r"(\d+)(xl|xs)", word)
    return m.group(2) + m.group(1) if m else word


def strip_prefix(name, prefix):
    if not name.startswith(prefix):
        fail("token %r does not start with %r" % (name, prefix))
    return name[len(prefix):]


def swift_name(family, name):
    if family == "color":
        return camel(name.split("-"))
    if family == "spacing":
        return "s" + strip_prefix(name, "spacing-").replace(".", "_")
    if family == "opacity":
        return "o" + strip_prefix(name, "opacity-")
    if family == "radius":
        return size_word(strip_prefix(name, "radius-"))
    if family == "shadow":
        return size_word(strip_prefix(name, "shadow-"))
    if family == "container":
        return size_word(strip_prefix(name, "container-"))
    if family == "text":
        return size_word(strip_prefix(name, "text-"))
    if family == "font-weight":
        return camel(strip_prefix(name, "font-weight-").split("-"))
    if family == "tracking":
        return camel(strip_prefix(name, "tracking-").split("-"))
    if family == "leading":
        return camel(strip_prefix(name, "leading-").split("-"))
    if family == "border-width":
        return camel(strip_prefix(name, "border-").split("-"))
    if family == "motion":
        return camel(name.split("-"))
    if family == "type":
        return camel(name.split("-"))
    fail("no naming rule for family %r" % family)


# ---------------------------------------------------------------- values

def fmt_num(x):
    """Shortest exact decimal for a float, always with a decimal point."""
    x = float(x)
    if x == int(x):
        return "%d" % int(x)
    s = repr(x)
    return s


def length_pt(raw, token):
    raw = str(raw).strip()
    m = re.fullmatch(r"(-?[\d.]+)(rem|px|em)?", raw)
    if not m:
        fail("cannot parse length %r in %s" % (raw, token))
    n, unit = float(m.group(1)), m.group(2)
    if unit == "rem":
        return n * PT_PER_REM
    return n  # px, em (kept as a multiplier) and unitless


def duration_s(raw, token):
    m = re.fullmatch(r"([\d.]+)(ms|s)", str(raw).strip())
    if not m:
        fail("cannot parse duration %r in %s" % (raw, token))
    n = float(m.group(1))
    return n / 1000.0 if m.group(2) == "ms" else n


def swift_doc(text, indent):
    if not text:
        return []
    text = " ".join(str(text).split())
    return ["%s/// %s" % (indent, text)]


def swift_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


# ---------------------------------------------------------------- colour

def parse_css_color(raw, where):
    """Returns ('hex', '#rrggbb') or ('rgba', (r, g, b, a))."""
    raw = raw.strip()
    m = re.fullmatch(r"#([0-9a-fA-F]{6})", raw)
    if m:
        return ("hex", "#" + m.group(1).lower())
    m = re.fullmatch(r"#([0-9a-fA-F]{3})", raw)
    if m:
        return ("hex", "#" + "".join(c * 2 for c in m.group(1).lower()))
    m = re.fullmatch(r"rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+)\s*)?\)", raw)
    if m:
        r, g, b = (float(m.group(i)) for i in (1, 2, 3))
        a = float(m.group(4)) if m.group(4) is not None else 1.0
        return ("rgba", (r, g, b, a))
    fail("cannot parse colour %r (%s)" % (raw, where))


def swift_fixed_color(parsed):
    kind, v = parsed
    if kind == "hex":
        return "SwiftUI.Color(hex: %s)" % swift_str(v)
    r, g, b, a = v
    return ("SwiftUI.Color(.sRGB, red: %s, green: %s, blue: %s, opacity: %s)"
            % (fmt_num(r / 255.0), fmt_num(g / 255.0), fmt_num(b / 255.0), fmt_num(a)))


class ColorResolver:
    def __init__(self, tokens):
        self.by_name = {t["name"]: t for t in tokens}

    def raw(self, name, theme, chain=()):
        if name in chain:
            fail("alias cycle: %s" % " -> ".join(chain + (name,)))
        tok = self.by_name.get(name)
        if tok is None:
            fail("unknown colour alias {%s}" % name)
        v = tok["value"]
        if isinstance(v, dict):
            raw = v.get(theme)
            if raw is None:
                raw = v.get("light")  # a missing dark value inherits light
            if raw is None:
                fail("colour %s has no light value" % name)
        else:
            raw = v
        raw = str(raw).strip()
        if raw.startswith("{") and raw.endswith("}"):
            return self.raw(raw[1:-1], theme, chain + (name,))
        return raw

    def source(self, name, theme):
        v = self.by_name[name]["value"]
        if isinstance(v, dict):
            raw = v.get(theme, v.get("light"))
        else:
            raw = v
        return str(raw)


def emit_colors(d, L):
    tokens = d["color"]["tokens"]
    themes = [t["id"] for t in d["color"]["themes"]]
    if themes != ["light", "dark"]:
        fail("expected themes [light, dark], got %r" % themes)
    res = ColorResolver(tokens)
    L.append("    /// `color` — %d tokens. Themes: light, dark. `{alias}` values are resolved per" % len(tokens))
    L.append("    /// theme; a token without a dark value uses its light value in dark.")
    L.append("    enum Color {")
    for t in tokens:
        name = t["name"]
        light = parse_css_color(res.raw(name, "light"), name)
        dark = parse_css_color(res.raw(name, "dark"), name)
        L += swift_doc(t.get("usage"), "        ")
        src_l, src_d = res.source(name, "light"), res.source(name, "dark")
        L.append("        /// tokens.json: light `%s` · dark `%s`" % (src_l, src_d))
        ident = swift_name("color", name)
        if light == dark:
            if light[0] == "hex":
                expr = "SwiftUI.Color(light: %s)" % swift_str(light[1])
            else:
                expr = swift_fixed_color(light)
        elif light[0] == "hex" and dark[0] == "hex":
            expr = "SwiftUI.Color(light: %s, dark: %s)" % (swift_str(light[1]), swift_str(dark[1]))
        else:
            expr = "SwiftUI.Color(light: %s, dark: %s)" % (swift_fixed_color(light), swift_fixed_color(dark))
        L.append("        static let %s = %s" % (ident, expr))
    L.append("    }")
    return len(tokens)


# ---------------------------------------------------------------- shadow

def split_layers(raw):
    out, depth, cur = [], 0, ""
    for ch in raw:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def parse_shadow_layer(raw, where):
    raw = raw.strip()
    inset = False
    if raw.startswith("inset "):
        inset = True
        raw = raw[len("inset "):].strip()
    m = re.search(r"(rgba?\([^)]*\)|#[0-9a-fA-F]{3,8})\s*$", raw)
    if not m:
        fail("shadow layer without a colour: %r (%s)" % (raw, where))
    color = parse_css_color(m.group(1), where)
    lengths = raw[:m.start()].split()
    if not 2 <= len(lengths) <= 4:
        fail("shadow layer needs 2–4 lengths: %r (%s)" % (raw, where))
    nums = [length_pt(x, where) for x in lengths] + [0.0] * (4 - len(lengths))
    x, y, blur, spread = nums
    return x, y, blur, spread, color, inset


def emit_shadows(d, L):
    tokens = d["shadow"]["tokens"]
    L.append("    /// `shadow` — %d tokens, parsed from CSS box-shadow lists into layers." % len(tokens))
    L += swift_doc(d["shadow"].get("note"), "    ")
    L.append("    enum Shadow {")
    for t in tokens:
        v = t["value"]
        if not isinstance(v, dict):
            v = {"light": v}
        L += swift_doc(t.get("usage"), "        ")
        ident = swift_name("shadow", t["name"])
        parts = []
        for theme in ("light", "dark"):
            raw = v.get(theme, v.get("light"))
            layers = [parse_shadow_layer(s, t["name"]) for s in split_layers(raw)]
            items = []
            for x, y, blur, spread, color, inset in layers:
                items.append("ShadowLayer(x: %s, y: %s, blur: %s, spread: %s, color: %s, inset: %s)"
                             % (fmt_num(x), fmt_num(y), fmt_num(blur), fmt_num(spread),
                                swift_fixed_color(color), "true" if inset else "false"))
            parts.append((theme, raw, items))
        L.append("        static let %s = ShadowToken(" % ident)
        for i, (theme, raw, items) in enumerate(parts):
            L.append("            // %s: %s" % (theme, raw))
            L.append("            %s: [" % theme)
            for it in items:
                L.append("                %s," % it)
            L.append("            ]%s" % ("," if i == 0 else ""))
        L.append("        )")
    L.append("    }")
    return len(tokens)


# ---------------------------------------------------------------- scalar families

SCALAR_FAMILIES = [
    # family, Swift enum, Swift type, converter, doc of the unit
    ("spacing", "Spacing", "CGFloat", "pt", "points (rem × 16)"),
    ("radius", "Radius", "CGFloat", "pt", "points (rem × 16; `full` is 9999)"),
    ("opacity", "Opacity", "Double", "num", "0–1"),
    ("container", "Container", "CGFloat", "pt", "points (rem × 16)"),
    ("text", "Text", "CGFloat", "pt", "font size in points (rem × 16)"),
    ("font-weight", "FontWeight", "Int", "int", "CSS numeric weight"),
    ("tracking", "Tracking", "CGFloat", "em", "em — multiply by the font size for points"),
    ("leading", "Leading", "CGFloat", "num", "line height as a multiple of the font size"),
    ("border-width", "BorderWidth", "CGFloat", "pt", "points"),
]


def convert_scalar(kind, raw, where):
    if kind == "pt":
        return fmt_num(length_pt(raw, where))
    if kind == "em":
        s = str(raw).strip()
        if not s.endswith("em"):
            fail("expected an em value for %s, got %r" % (where, raw))
        return fmt_num(float(s[:-2]))
    if kind == "int":
        return "%d" % int(str(raw).strip())
    return fmt_num(float(str(raw).strip()))


def emit_scalars(d, L, family, enum, typ, kind, unit):
    tokens = d[family]["tokens"]
    L.append("    /// `%s` — %d tokens, in %s." % (family, len(tokens), unit))
    L += swift_doc(d[family].get("note"), "    ")
    L.append("    enum %s {" % enum)
    for t in tokens:
        if isinstance(t["value"], dict):
            fail("themed value in scalar family %s (%s)" % (family, t["name"]))
        L += swift_doc(t.get("usage"), "        ")
        L.append("        /// tokens.json: `%s` = `%s`" % (t["name"], t["value"]))
        L.append("        static let %s: %s = %s"
                 % (swift_name(family, t["name"]), typ, convert_scalar(kind, t["value"], t["name"])))
    L.append("    }")
    return len(tokens)


def emit_motion(d, L):
    tokens = d["motion"]["tokens"]
    L.append("    /// `motion` — %d tokens. Durations in seconds; scales as multipliers; easing as" % len(tokens))
    L.append("    /// the CSS keyword (map it to an `Animation` in hand-written code).")
    L += swift_doc(d["motion"].get("note"), "    ")
    L.append("    enum Motion {")
    for t in tokens:
        name, raw = t["name"], str(t["value"]).strip()
        L += swift_doc(t.get("usage"), "        ")
        L.append("        /// tokens.json: `%s` = `%s`" % (name, raw))
        ident = swift_name("motion", name)
        if name.startswith("duration-"):
            L.append("        static let %s: Double = %s" % (ident, fmt_num(duration_s(raw, name))))
        elif name.startswith("ease-"):
            L.append("        static let %s: String = %s" % (ident, swift_str(raw)))
        elif name.startswith("scale-"):
            L.append("        static let %s: CGFloat = %s" % (ident, fmt_num(float(raw))))
        else:
            fail("no motion rule for %s" % name)
    L.append("    }")
    return len(tokens)


# ---------------------------------------------------------------- type

def ttf_postscript_name(path):
    data = open(path, "rb").read()
    num = struct.unpack(">H", data[4:6])[0]
    for i in range(num):
        tag, _, off, _ = struct.unpack(">4sIII", data[12 + 16 * i:28 + 16 * i])
        if tag != b"name":
            continue
        _, count, str_off = struct.unpack(">HHH", data[off:off + 6])
        for j in range(count):
            pid, _, _, nid, ln, so = struct.unpack(">HHHHHH", data[off + 6 + 12 * j:off + 18 + 12 * j])
            if nid == 6 and pid == 3:
                start = off + str_off + so
                return data[start:start + ln].decode("utf-16-be")
    fail("no PostScript name in %s" % path)


def first_family(css_stack):
    m = re.match(r'\s*"([^"]+)"', css_stack)
    return m.group(1) if m else None


def parse_dynamic_type(readme_text):
    """Reads the README's `#### Dynamic Type` table: step -> iOS text style."""
    m = re.search(r"^#{2,4} Dynamic Type\s*$(.*?)(?=^#{1,4} )", readme_text, re.S | re.M)
    if not m:
        fail("README.md has no 'Dynamic Type' section")
    mapping = {}
    for line in m.group(1).splitlines():
        row = re.match(r"\|\s*`([a-z]+-[a-z]+)`\s*\|\s*`\.(\w+)`", line)
        if row:
            style = row.group(2)
            if style not in SWIFT_TEXT_STYLES:
                fail("README Dynamic Type: unknown iOS text style .%s" % style)
            mapping[row.group(1)] = style
    return mapping


def emit_type(d, L, scalar_lookup, dynamic_type):
    ty = d["type"]
    fonts = ty["fonts"]
    families = ty["families"]

    L.append("    /// `type.families` — the CSS stacks, and the bundled font each resolves to on iOS.")
    L.append("    /// PostScript names are read from the .ttf files `type.fonts` lists (bundled in")
    L.append("    /// `Core/Fonts/`). `nil` means the platform system font (SF Pro).")
    L.append("    enum Font {")
    family_cases = []
    count = 0
    for key in sorted(families):
        stack = families[key]
        fam = first_family(stack)
        ident = camel(key.split("-"))
        family_cases.append((key, ident))
        L.append("        /// tokens.json `%s`: %s" % (key, stack))
        regular = italic = None
        if fam is not None:
            for f in fonts:
                if f["family"] != fam:
                    continue
                path = os.path.join(FONTS_DIR, os.path.basename(f["file"]))
                if not os.path.exists(path):
                    fail("font file %s (from tokens.json) is not bundled at %s" % (f["file"], path))
                ps = ttf_postscript_name(path)
                if f["style"] == "italic":
                    italic = ps
                else:
                    regular = ps
            if regular is None:
                fail("family %s (%r) has no upright font in type.fonts" % (key, fam))
        L.append("        static let %s: String? = %s" % (ident, swift_str(regular) if regular else "nil"))
        L.append("        static let %sItalic: String? = %s" % (ident, swift_str(italic) if italic else "nil"))
        count += 1
    L.append("    }")
    L.append("")

    L.append("    /// The font family a type style is set in (`type.families` keys).")
    L.append("    enum FontFamily: String, CaseIterable {")
    for key, ident in family_cases:
        L.append("        case %s = %s" % (ident, swift_str(key)))
    L.append("")
    L.append("        /// PostScript name of the upright cut; `nil` = system font.")
    L.append("        var postScriptName: String? {")
    L.append("            switch self {")
    for key, ident in family_cases:
        L.append("            case .%s: return Font.%s" % (ident, ident))
    L.append("            }")
    L.append("        }")
    L.append("")
    L.append("        /// PostScript name of the italic cut, when the family bundles one.")
    L.append("        var italicPostScriptName: String? {")
    L.append("            switch self {")
    for key, ident in family_cases:
        L.append("            case .%s: return Font.%sItalic" % (ident, ident))
    L.append("            }")
    L.append("        }")
    L.append("    }")
    L.append("")

    L.append("    /// One step of the type scale: a family, a `text-*` size, a `leading-*` step and a")
    L.append("    /// weight, plus the iOS text style it scales with (README \"Dynamic Type\").")
    L.append("    struct TypeStyle {")
    L.append("        let name: String")
    L.append("        let family: FontFamily")
    L.append("        let size: CGFloat")
    L.append("        let lineHeight: CGFloat")
    L.append("        let weight: Int")
    L.append("        let relativeTo: SwiftUI.Font.TextStyle")
    L.append("    }")
    L.append("")
    L.append("    /// `type.groups` — %d styles." % sum(len(g["styles"]) for g in ty["groups"]))
    L.append("    enum TypeStyles {")
    style_idents = []
    for g in ty["groups"]:
        L += swift_doc("%s: %s" % (g["name"], g.get("note", "")), "        ")
        for st in g["styles"]:
            name = st["name"]
            fam_key = st.get("family", g["family"])
            fam_ident = dict(family_cases).get(fam_key)
            if fam_ident is None:
                fail("style %s uses unknown family %s" % (name, fam_key))
            size = length_pt(st["fontSize"], name)
            size_ref = scalar_lookup("text", size)
            lh_ref = scalar_lookup("leading", float(st["lineHeight"]))
            w_ref = scalar_lookup("font-weight", int(st["fontWeight"]))
            if size_ref is None or lh_ref is None or w_ref is None:
                fail("style %s does not land on text/leading/font-weight tokens" % name)
            rel = dynamic_type.get(name)
            if rel is None:
                fail("style %s is missing from the README Dynamic Type table" % name)
            ident = swift_name("type", name)
            style_idents.append(ident)
            L += swift_doc(st.get("usage"), "        ")
            L.append("        static let %s = TypeStyle(" % ident)
            L.append("            name: %s, family: .%s," % (swift_str(name), fam_ident))
            L.append("            size: %s, lineHeight: %s, weight: %s," % (size_ref, lh_ref, w_ref))
            L.append("            relativeTo: .%s" % rel)
            L.append("        )")
            count += 1
    L.append("")
    L.append("        static let all: [TypeStyle] = [%s]" % ", ".join(style_idents))
    L.append("    }")
    return count


# ---------------------------------------------------------------- main

def build():
    d = json.load(open(TOKENS, encoding="utf-8"))
    unknown = set(d) - KNOWN_FAMILIES
    if unknown:
        fail("tokens.json has families this generator does not emit: %s" % ", ".join(sorted(unknown)))
    readme = open(README, encoding="utf-8").read()
    dynamic_type = parse_dynamic_type(readme)
    version = open(VERSION, encoding="utf-8").read().strip().splitlines() if os.path.exists(VERSION) else []

    # value -> Swift reference, for type styles
    lookup_tables = {}
    for family, enum, typ, kind, _ in SCALAR_FAMILIES:
        table = {}
        for t in d[family]["tokens"]:
            val = convert_scalar(kind, t["value"], t["name"])
            table.setdefault(float(val), "%s.%s" % (enum, swift_name(family, t["name"])))
        lookup_tables[family] = table

    def scalar_lookup(family, value):
        return lookup_tables[family].get(float(value))

    L = []
    L.append("// GENERATED — do not edit.")
    L.append("// Source: design-system/tokens.json (tokens version %s, \"%s\")" % (d.get("version"), d.get("name")))
    for line in version:
        L.append("//   %s" % line)
    L.append("// Dynamic Type mapping: design-system/README.md, \"Dynamic Type\".")
    L.append("// Regenerate: python3 scripts/ds-tokens-swift.py")
    L.append("// swiftlint:disable all")
    L.append("")
    L.append("import SwiftUI")
    L.append("")
    L.append("/// Raw design-system tokens, 1:1 with `tokens.json`. Views use the semantic")
    L.append("/// aliases in `DS` (Core/Design/DS+*.swift), which point here.")
    L.append("enum DSTokens {")
    L.append("    static let version = %d" % int(d.get("version", 0)))
    L.append("    static let name = %s" % swift_str(str(d.get("name", ""))))
    L.append("")
    L.append("    /// One layer of a CSS box-shadow, in points.")
    L.append("    struct ShadowLayer {")
    L.append("        let x: CGFloat")
    L.append("        let y: CGFloat")
    L.append("        let blur: CGFloat")
    L.append("        let spread: CGFloat")
    L.append("        let color: SwiftUI.Color")
    L.append("        let inset: Bool")
    L.append("    }")
    L.append("")
    L.append("    /// A shadow token: its layer list in each theme.")
    L.append("    struct ShadowToken {")
    L.append("        let light: [ShadowLayer]")
    L.append("        let dark: [ShadowLayer]")
    L.append("    }")
    L.append("")

    counts = {}
    counts["color"] = emit_colors(d, L)
    L.append("")
    for family, enum, typ, kind, unit in SCALAR_FAMILIES:
        counts[family] = emit_scalars(d, L, family, enum, typ, kind, unit)
        L.append("")
    counts["shadow"] = emit_shadows(d, L)
    L.append("")
    counts["motion"] = emit_motion(d, L)
    L.append("")
    counts["type"] = emit_type(d, L, scalar_lookup, dynamic_type)
    L.append("}")
    L.append("")

    total = sum(counts.values())
    summary = ", ".join("%s %d" % (k, counts[k]) for k in sorted(counts))
    L.insert(5, "// Tokens: %d (%s)" % (total, summary))
    return "\n".join(L), total, summary


def main():
    text, total, summary = build()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    old = open(OUT, encoding="utf-8").read() if os.path.exists(OUT) else None
    if old != text:
        with open(OUT, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        state = "written"
    else:
        state = "unchanged"
    print("DSTokens.generated.swift %s: %d tokens (%s)" % (state, total, summary), file=sys.stderr)


if __name__ == "__main__":
    main()
