#!/usr/bin/env bash
# ds-lint: fail on values that did not come from the design system.
#
# Scans Swift files in apps/ios/NomNom/Core/Components, Core/Extensions, Core/Design
# (except Core/Design/Generated, which scripts/ds-tokens-swift.py writes from
# tokens.json) and apps/ios/NomNom/Features for invented values: numeric literals in font sizes, padding, spacing, frames and
# sizes, corner radii, opacities, line widths, line spacing, tracking, scale and
# shadow/blur radii; colour literals (Color(red:/white:/hex:), "#rrggbb" strings);
# and named system colours (Color.red, .foregroundStyle(.white), …).
#
# Allowed: the literals 0 and 1 (e.g. `.opacity(1)`, `spacing: 0`, `scaleEffect(1)`),
# comment lines, and any line ending in `// ds-lint:allow <reason>`.
#
# Usage: scripts/ds-lint.sh [--summary] [path ...]
#   --summary   print only the counts
# Exit status: 0 when clean, 1 when anything is found.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUMMARY_ONLY=0
if [[ "${1:-}" == "--summary" ]]; then SUMMARY_ONLY=1; shift; fi

if [[ $# -gt 0 ]]; then
  TARGETS=("$@")
else
  TARGETS=(
    "$ROOT/apps/ios/NomNom/Core/Components"
    "$ROOT/apps/ios/NomNom/Core/Extensions"
    "$ROOT/apps/ios/NomNom/Core/Design"
    "$ROOT/apps/ios/NomNom/Features"
  )
fi

FILES=()
while IFS= read -r -d '' f; do FILES+=("$f"); done < <(
  find "${TARGETS[@]}" -type f -name '*.swift' -not -path '*/Core/Design/Generated/*' -print0 | sort -z
)
if [[ ${#FILES[@]} -eq 0 ]]; then echo "ds-lint: no Swift files found"; exit 0; fi

HITS="$(awk -v root="$ROOT/" '
BEGIN {
  NUM = "-?[0-9]+(\\.[0-9]+)?"
  n = 0
  # rule name, regex, numeric (1 = allow 0 and 1)
  r[++n] = "font-size";    re[n] = "(\\.system\\(size|systemFont\\(ofSize|[^A-Za-z]size): *" NUM;           num[n] = 1
  r[++n] = "padding";      re[n] = "\\.padding\\((\\.[A-Za-z]+, *|\\[[.A-Za-z, ]*\\], *)?" NUM;            num[n] = 1
  r[++n] = "spacing";      re[n] = "[^A-Za-z]spacing: *" NUM;                                              num[n] = 1
  r[++n] = "dimension";    re[n] = "[^A-Za-z](width|height|minWidth|minHeight|maxWidth|maxHeight|idealWidth|idealHeight): *" NUM; num[n] = 1
  r[++n] = "radius";       re[n] = "([Cc]ornerRadius|[^A-Za-z]radius): *" NUM;                             num[n] = 1
  r[++n] = "opacity";      re[n] = "(\\.opacity\\(|[^A-Za-z]opacity: *)" NUM;                              num[n] = 1
  r[++n] = "line-width";   re[n] = "lineWidth: *" NUM;                                                     num[n] = 1
  r[++n] = "line-spacing"; re[n] = "\\.lineSpacing\\(" NUM;                                                num[n] = 1
  r[++n] = "tracking";     re[n] = "\\.(tracking|kerning)\\(" NUM;                                         num[n] = 1
  r[++n] = "scale";        re[n] = "\\.scaleEffect\\(" NUM;                                                num[n] = 1
  r[++n] = "color-literal"; re[n] = "(UI)?Color\\((red|white|hue|hex|\\.sRGB|\\.displayP3)[:,]";           num[n] = 0
  r[++n] = "hex-string";   re[n] = "\"#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]"; num[n] = 0
  NAMED = "(red|green|blue|orange|yellow|black|white|gray|grey|pink|purple|teal|mint|cyan|indigo|brown|accentColor)"
  r[++n] = "named-color";  re[n] = "(UI)?Color\\." NAMED "([^A-Za-z0-9_]|$)";                             num[n] = 0
  r[++n] = "named-color";  re[n] = "(foregroundStyle|foregroundColor|fill|tint|background|stroke|strokeBorder)\\(\\." NAMED "([^A-Za-z0-9_]|$)"; num[n] = 0
  r[++n] = "named-color";  re[n] = "[^A-Za-z]color: *\\." NAMED "([^A-Za-z0-9_]|$)";                       num[n] = 0
}
/ds-lint:allow/ { next }
/^[ \t]*\/\// { next }
{
  line = " " $0
  for (i = 1; i <= n; i++) {
    s = line
    while (match(s, re[i])) {
      m = substr(s, RSTART, RLENGTH)
      s = substr(s, RSTART + RLENGTH)
      if (num[i]) {
        if (match(m, "-?[0-9]+(\\.[0-9]+)?$")) {
          v = substr(m, RSTART, RLENGTH) + 0
          if (v == 0 || v == 1) continue
        }
      }
      f = FILENAME; sub("^" root, "", f)
      gsub(/^[^A-Za-z.]+/, "", m); gsub(/[^A-Za-z0-9]+$/, "", m)
      printf "%s:%d: %s: %s\n", f, FNR, r[i], m
    }
  }
}
' "${FILES[@]}")"

if [[ -z "$HITS" ]]; then
  echo "ds-lint: clean (${#FILES[@]} files)"
  exit 0
fi

if [[ $SUMMARY_ONLY -eq 0 ]]; then
  echo "$HITS"
  echo
fi

TOTAL=$(printf '%s\n' "$HITS" | wc -l | tr -d ' ')
CORE=$(printf '%s\n' "$HITS" | grep -c '^apps/ios/NomNom/Core/' || true)
FEAT=$(printf '%s\n' "$HITS" | grep -c '^apps/ios/NomNom/Features/' || true)
echo "ds-lint: $TOTAL invented values (Core $CORE, Features $FEAT) in ${#FILES[@]} files"
echo "by rule:"
printf '%s\n' "$HITS" | awk -F': ' '{print $2}' | sort | uniq -c | sort -rn | sed 's/^/  /'
echo "top files:"
printf '%s\n' "$HITS" | cut -d: -f1 | sort | uniq -c | sort -rn | head -10 | sed 's/^/  /'
exit 1
