// GENERATED — do not edit.
// Source: design-system/tokens.json (tokens version 1, "Nom Nom")
//   source: https://claude.ai/artifact/4jeEJ91V5eRxpDn8NtqNgK
//   version: 1791206212-d0ff
//   downloaded: 2026-10-05
// Tokens: 179 (border-width 2, color 78, container 3, font-weight 2, leading 5, motion 8, opacity 16, radius 8, shadow 7, spacing 25, text 10, tracking 2, type 13)
// Dynamic Type mapping: design-system/README.md, "Dynamic Type".
// Regenerate: python3 scripts/ds-tokens-swift.py
// swiftlint:disable all

import SwiftUI

/// Raw design-system tokens, 1:1 with `tokens.json`. Views use the semantic
/// aliases in `DS` (Core/Design/DS+*.swift), which point here.
enum DSTokens {
    static let version = 1
    static let name = "Nom Nom"

    /// One layer of a CSS box-shadow, in points.
    struct ShadowLayer {
        let x: CGFloat
        let y: CGFloat
        let blur: CGFloat
        let spread: CGFloat
        let color: SwiftUI.Color
        let inset: Bool
    }

    /// A shadow token: its layer list in each theme.
    struct ShadowToken {
        let light: [ShadowLayer]
        let dark: [ShadowLayer]
    }

    /// `color` — 78 tokens. Themes: light, dark. `{alias}` values are resolved per
    /// theme; a token without a dark value uses its light value in dark.
    enum Color {
        /// Screen ground behind every list and scroll view. Cards sit on it with no border and no shadow — the white-on-grey step is the separation.
        /// tokens.json: light `{stone-100}` · dark `{stone-1000}`
        static let bg = SwiftUI.Color(light: "#eff1f4", dark: "#06080c")
        /// Cards, rows, the floating icon button, photo score chips. Dark uses stone-900 (iOS grouped style) so a borderless card still reads against `bg` (1.23:1 in dark; the old stone-950 was 1.07:1).
        /// tokens.json: light `{stone-0}` · dark `{stone-900}`
        static let panel = SwiftUI.Color(light: "#ffffff", dark: "#1c2026")
        /// Filled inputs, the in-sheet close button, subtle ScoreBadge, placeholders.
        /// tokens.json: light `{stone-200}` · dark `{stone-800}`
        static let sunken = SwiftUI.Color(light: "#e3e5e9", dark: "#31363c")
        /// Bottom-sheet ground; its cards are `panel`.
        /// tokens.json: light `{stone-50}` · dark `{stone-950}`
        static let sheet = SwiftUI.Color(light: "#f5f7f9", dark: "#0f1217")
        /// 1px row dividers inside a card list. Decorative only.
        /// tokens.json: light `{stone-100}` · dark `{stone-800}`
        static let line = SwiftUI.Color(light: "#eff1f4", dark: "#31363c")
        /// Timeline rail and other purely decorative rules. Deliberately below 3:1 — a line that carries meaning (a control's border) uses `line-control`.
        /// tokens.json: light `{stone-300}` · dark `{stone-700}`
        static let lineStrong = SwiftUI.Color(light: "#d0d4d9", dark: "#4d525a")
        /// Border of an outlined control: outline buttons, outlined inputs, the `oneAndDone` pill. At least 3:1 on `panel`, `bg`, `sunken` and `sheet` in both themes, which a control border must meet.
        /// tokens.json: light `{stone-600}` · dark `{stone-500}`
        static let lineControl = SwiftUI.Color(light: "#6b7178", dark: "#8a8f97")
        /// The unfilled part of a Bar, and a Toggle's off track. Deliberately low against the surface: a meter is read by where its fill ends, and fill-against-track is 5.2:1 light / 3.6:1 dark, which is what 1.4.11 asks of the part that carries the meaning. Raising the track would lower that.
        /// tokens.json: light `{stone-200}` · dark `{stone-800}`
        static let track = SwiftUI.Color(light: "#e3e5e9", dark: "#31363c")
        /// Dims the screen behind a sheet.
        /// tokens.json: light `rgba(0, 0, 0, 0.4)` · dark `rgba(0, 0, 0, 0.6)`
        static let scrim = SwiftUI.Color(light: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.4), dark: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.6))
        /// The sheet's drag handle. Aliases `line-control`: it is an affordance, not decoration, so it clears 3:1 on `sheet` (WCAG 1.4.11).
        /// tokens.json: light `{line-control}` · dark `{line-control}`
        static let grabber = SwiftUI.Color(light: "#6b7178", dark: "#8a8f97")
        /// Titles, names, scores' verdict words, input text: 16.0:1 on `bg` light, 17.7:1 dark.
        /// tokens.json: light `#16181a` · dark `{stone-100}`
        static let textPrimary = SwiftUI.Color(light: "#16181a", dark: "#eff1f4")
        /// Body copy and summaries under a title: 9.6:1 on `bg` light, 11.0:1 on `panel` dark.
        /// tokens.json: light `#3a3f45` · dark `{stone-300}`
        static let textSecondary = SwiftUI.Color(light: "#3a3f45", dark: "#d0d4d9")
        /// Meta lines, section labels, captions, 'as usual', placeholders: 5.6:1 on `bg`, 6.3:1 on `panel`, 5.2:1 on `sunken` light; 7.6:1 on `panel` dark.
        /// tokens.json: light `#5b6168` · dark `{stone-400}`
        static let textTertiary = SwiftUI.Color(light: "#5b6168", dark: "#adb1b8")
        /// Keyboard focus: 2px solid outline, 2px offset.
        /// tokens.json: light `{pine-600}` · dark `{pine-300}`
        static let focusRing = SwiftUI.Color(light: "#0a6867", dark: "#87ccca")
        /// Primary role fill: solid primary buttons and badges, progress fill, current timeline dot, chevrons. `on-primary` on it is 6.4:1 light; 2.98:1 dark (kept from the app's dark pine).
        /// tokens.json: light `{pine-600}` · dark `{pine-400}`
        static let primary = SwiftUI.Color(light: "#0a6867", dark: "#4aa3a0")
        /// Primary role soft ground (soft buttons and badges, avatar fallback). Carries `primary-text`.
        /// tokens.json: light `#e3f1ee` · dark `{pine-900}`
        static let primarySoft = SwiftUI.Color(light: "#e3f1ee", dark: "#002a29")
        /// Primary role text: soft/outline/ghost primary buttons and badges, counts, positive deltas, score numerals. 6.4:1 on `panel`, 5.5:1 on `primary-soft` light; 9.0:1 on `panel` dark.
        /// tokens.json: light `{pine-600}` · dark `{pine-300}`
        static let primaryText = SwiftUI.Color(light: "#0a6867", dark: "#87ccca")
        /// Text and icons on a solid `primary` fill. Dark `primary` is the light pine-400 fill, so its ink is pine-900 (5.16:1); white would be 2.98:1.
        /// tokens.json: light `#ffffff` · dark `{pine-900}`
        static let onPrimary = SwiftUI.Color(light: "#ffffff", dark: "#002a29")
        /// Past timeline dots (the current one is `primary`). A mark, not text.
        /// tokens.json: light `#8fbfb4` · dark `{pine-700}`
        static let primaryMuted = SwiftUI.Color(light: "#8fbfb4", dark: "#055150")
        /// Secondary role fill: solid secondary buttons and badges — ink on light, light on dark.
        /// tokens.json: light `{text-primary}` · dark `{text-primary}`
        static let secondary = SwiftUI.Color(light: "#16181a", dark: "#eff1f4")
        /// Secondary role soft ground: soft secondary buttons (Reset Filters, sheet close) and badges.
        /// tokens.json: light `{sunken}` · dark `{sunken}`
        static let secondarySoft = SwiftUI.Color(light: "#e3e5e9", dark: "#31363c")
        /// Secondary role text: soft/outline/ghost secondary. 8.8:1 on `secondary-soft` light, 8.2:1 dark.
        /// tokens.json: light `{text-secondary}` · dark `{text-secondary}`
        static let secondaryText = SwiftUI.Color(light: "#3a3f45", dark: "#d0d4d9")
        /// Text on a solid `secondary` fill: 17.8:1 light, 14.5:1 dark.
        /// tokens.json: light `{panel}` · dark `{panel}`
        static let onSecondary = SwiftUI.Color(light: "#ffffff", dark: "#1c2026")
        /// Destructive role fill: solid destructive buttons, irreversible actions only. iOS system red darkened 15% (same hue) so white text reaches 4.7:1 light and 4.6:1 dark; the undarkened #ff3b30 gave 3.6:1.
        /// tokens.json: light `#d93229` · dark `#d93b31`
        static let destructive = SwiftUI.Color(light: "#d93229", dark: "#d93b31")
        /// Destructive role soft ground.
        /// tokens.json: light `#ffe2e0` · dark `#3e2629`
        static let destructiveSoft = SwiftUI.Color(light: "#ffe2e0", dark: "#3e2629")
        /// Red text on a pale ground: inline errors, destructive labels. Dark value clears 4.5:1 on `sunken` (the field ground), not just on `panel`.
        /// tokens.json: light `#c4001a` · dark `#ff8178`
        static let destructiveText = SwiftUI.Color(light: "#c4001a", dark: "#ff8178")
        /// Text and icons on a solid `destructive` fill. White both themes: 4.73:1 light, 4.55:1 dark.
        /// tokens.json: light `#ffffff` · dark `#ffffff`
        static let onDestructive = SwiftUI.Color(light: "#ffffff")
        /// Pro role fill: solid Pro buttons ("Unlock with Pro"). `on-pro` on it 15.8:1 / 10.4:1.
        /// tokens.json: light `#2b174d` · dark `#4a2f82`
        static let pro = SwiftUI.Color(light: "#2b174d", dark: "#4a2f82")
        /// Pro role soft ground (Pro badges, gated-card grounds). Violet means Pro and nothing else.
        /// tokens.json: light `#f4f0f9` · dark `#1a1130`
        static let proSoft = SwiftUI.Color(light: "#f4f0f9", dark: "#1a1130")
        /// Pro label text. Dark value clears 4.5:1 on `sunken`.
        /// tokens.json: light `#7242c2` · dark `#b398ea`
        static let proText = SwiftUI.Color(light: "#7242c2", dark: "#b398ea")
        /// Text on a solid `pro` fill.
        /// tokens.json: light `#ffffff` · dark `#ffffff`
        static let onPro = SwiftUI.Color(light: "#ffffff")
        /// Warning role fill (solid warning badges). `on-warning` on it 6.5:1 / 6.8:1.
        /// tokens.json: light `{warning-text}` · dark `{warning-text}`
        static let warning = SwiftUI.Color(light: "#9a4418", dark: "#ee8e64")
        /// Warning role soft ground: a negative change badge ('−2').
        /// tokens.json: light `#fbede4` · dark `#2e1a10`
        static let warningSoft = SwiftUI.Color(light: "#fbede4", dark: "#2e1a10")
        /// Warning role text: negative change ('−2', '−4 usual'). 5.7:1 on `warning-soft`, 6.5:1 on `panel` light; 6.8:1 dark.
        /// tokens.json: light `#9a4418` · dark `#ee8e64`
        static let warningText = SwiftUI.Color(light: "#9a4418", dark: "#ee8e64")
        /// Text on a solid `warning` fill.
        /// tokens.json: light `#ffffff` · dark `{panel}`
        static let onWarning = SwiftUI.Color(light: "#ffffff", dark: "#1c2026")
        /// Reaction −1 · Can't eat: shape fill only — 14–20% tint grounds, 1.5pt selected borders, dots, meter stops. Never behind text at full strength.
        /// tokens.json: light `#bf3a37` · dark `#e97970`
        static let reactionInedibleFill = SwiftUI.Color(light: "#bf3a37", dark: "#e97970")
        /// Can't eat, as text. Dark value clears 4.5:1 on `sunken`.
        /// tokens.json: light `#a51e21` · dark `#f49d96`
        static let reactionInedibleText = SwiftUI.Color(light: "#a51e21", dark: "#f49d96")
        /// Reaction 1 · Bad: shape fill only — 14–20% tint grounds, 1.5pt selected borders, dots, meter stops. Never behind text at full strength.
        /// tokens.json: light `#d16633` · dark `#ee8e64`
        static let reactionBadFill = SwiftUI.Color(light: "#d16633", dark: "#ee8e64")
        /// Reaction 1 · Bad: numeral and label ink on `panel` or on its own 14–20% fill tint (≥4.9:1 in both themes). In dark one value serves fill and text.
        /// tokens.json: light `#9b3400` · dark `#ee8e64`
        static let reactionBadText = SwiftUI.Color(light: "#9b3400", dark: "#ee8e64")
        /// Reaction 2 · Meh: shape fill only — 14–20% tint grounds, 1.5pt selected borders, dots, meter stops. Never behind text at full strength.
        /// tokens.json: light `#d3a032` · dark `#e4b65c`
        static let reactionMehFill = SwiftUI.Color(light: "#d3a032", dark: "#e4b65c")
        /// Reaction 2 · Meh: numeral and label ink on `panel` or on its own 14–20% fill tint (≥4.9:1 in both themes). In dark one value serves fill and text.
        /// tokens.json: light `#774d00` · dark `#e4b65c`
        static let reactionMehText = SwiftUI.Color(light: "#774d00", dark: "#e4b65c")
        /// Reaction 3 · Good: shape fill only — 14–20% tint grounds, 1.5pt selected borders, dots, meter stops. Never behind text at full strength.
        /// tokens.json: light `#7ba853` · dark `#a0ca7f`
        static let reactionGoodFill = SwiftUI.Color(light: "#7ba853", dark: "#a0ca7f")
        /// Reaction 3 · Good: numeral and label ink on `panel` or on its own 14–20% fill tint (≥4.9:1 in both themes). In dark one value serves fill and text.
        /// tokens.json: light `#3c6211` · dark `#a0ca7f`
        static let reactionGoodText = SwiftUI.Color(light: "#3c6211", dark: "#a0ca7f")
        /// Reaction 4 · Great: shape fill only — 14–20% tint grounds, 1.5pt selected borders, dots, meter stops. Never behind text at full strength.
        /// tokens.json: light `#2e985e` · dark `#71c791`
        static let reactionGreatFill = SwiftUI.Color(light: "#2e985e", dark: "#71c791")
        /// Reaction 4 · Great: numeral and label ink on `panel` or on its own 14–20% fill tint (≥4.9:1 in both themes). In dark one value serves fill and text.
        /// tokens.json: light `#006836` · dark `#71c791`
        static let reactionGreatText = SwiftUI.Color(light: "#006836", dark: "#71c791")
        /// Reaction 5 · Amazing: shape fill only — 14–20% tint grounds, 1.5pt selected borders, dots, meter stops. Never behind text at full strength.
        /// tokens.json: light `#247f63` · dark `#62bc9c`
        static let reactionAmazingFill = SwiftUI.Color(light: "#247f63", dark: "#62bc9c")
        /// Reaction 5 · Amazing: numeral and label ink on `panel` or on its own 14–20% fill tint (≥4.9:1 in both themes). In dark one value serves fill and text.
        /// tokens.json: light `#00684c` · dark `#62bc9c`
        static let reactionAmazingText = SwiftUI.Color(light: "#00684c", dark: "#62bc9c")
        /// Chart categorical #1 (Cerulean — default secondary comparison series). Assign by stable index per party member, never cycle. Violet deliberately absent (reserved for Pro); the party total line is `primary`.
        /// tokens.json: light `#2a78d6` · dark `#3987e5`
        static let chartSeries1 = SwiftUI.Color(light: "#2a78d6", dark: "#3987e5")
        /// Chart categorical #2 (Orange). Assign by stable index per party member, never cycle. Violet deliberately absent (reserved for Pro); the party total line is `primary`.
        /// tokens.json: light `#c84f1d` · dark `#d95926`
        static let chartSeries2 = SwiftUI.Color(light: "#c84f1d", dark: "#d95926")
        /// Chart categorical #3 (Green). Assign by stable index per party member, never cycle. Violet deliberately absent (reserved for Pro); the party total line is `primary`.
        /// tokens.json: light `#13845b` · dark `#199e70`
        static let chartSeries3 = SwiftUI.Color(light: "#13845b", dark: "#199e70")
        /// Chart categorical #4 (Amber). Assign by stable index per party member, never cycle. Violet deliberately absent (reserved for Pro); the party total line is `primary`.
        /// tokens.json: light `#a86f00` · dark `#c98500`
        static let chartSeries4 = SwiftUI.Color(light: "#a86f00", dark: "#c98500")
        /// Chart categorical #5 (Pink). Assign by stable index per party member, never cycle. Violet deliberately absent (reserved for Pro); the party total line is `primary`.
        /// tokens.json: light `#c2507c` · dark `#d55181`
        static let chartSeries5 = SwiftUI.Color(light: "#c2507c", dark: "#d55181")
        /// Chart categorical #6 (Deep green). Assign by stable index per party member, never cycle. Violet deliberately absent (reserved for Pro); the party total line is `primary`.
        /// tokens.json: light `#008300` · dark `#008300`
        static let chartSeries6 = SwiftUI.Color(light: "#008300")
        /// Chart categorical #7 (Red). Assign by stable index per party member, never cycle. Violet deliberately absent (reserved for Pro); the party total line is `primary`.
        /// tokens.json: light `#e34948` · dark `#e66767`
        static let chartSeries7 = SwiftUI.Color(light: "#e34948", dark: "#e66767")
        /// Stone ramp (OKLCH hue 258°, cool on purpose so food photography supplies the warmth). Ramp step — views consume the semantic roles, not this.
        /// tokens.json: light `#ffffff` · dark `#ffffff`
        static let stone0 = SwiftUI.Color(light: "#ffffff")
        /// Stone ramp (OKLCH hue 258°, cool on purpose so food photography supplies the warmth). Ramp step — views consume the semantic roles, not this.
        /// tokens.json: light `#fafbfc` · dark `#fafbfc`
        static let stone25 = SwiftUI.Color(light: "#fafbfc")
        /// Stone ramp (OKLCH hue 258°, cool on purpose so food photography supplies the warmth). Ramp step — views consume the semantic roles, not this.
        /// tokens.json: light `#f5f7f9` · dark `#f5f7f9`
        static let stone50 = SwiftUI.Color(light: "#f5f7f9")
        /// Stone ramp (OKLCH hue 258°, cool on purpose so food photography supplies the warmth). Ramp step — views consume the semantic roles, not this.
        /// tokens.json: light `#eff1f4` · dark `#eff1f4`
        static let stone100 = SwiftUI.Color(light: "#eff1f4")
        /// Stone ramp (OKLCH hue 258°, cool on purpose so food photography supplies the warmth). Ramp step — views consume the semantic roles, not this.
        /// tokens.json: light `#e3e5e9` · dark `#e3e5e9`
        static let stone200 = SwiftUI.Color(light: "#e3e5e9")
        /// Stone ramp (OKLCH hue 258°, cool on purpose so food photography supplies the warmth). Ramp step — views consume the semantic roles, not this.
        /// tokens.json: light `#d0d4d9` · dark `#d0d4d9`
        static let stone300 = SwiftUI.Color(light: "#d0d4d9")
        /// Stone ramp (OKLCH hue 258°, cool on purpose so food photography supplies the warmth). Ramp step — views consume the semantic roles, not this.
        /// tokens.json: light `#adb1b8` · dark `#adb1b8`
        static let stone400 = SwiftUI.Color(light: "#adb1b8")
        /// Stone ramp (OKLCH hue 258°, cool on purpose so food photography supplies the warmth). Ramp step — views consume the semantic roles, not this.
        /// tokens.json: light `#8a8f97` · dark `#8a8f97`
        static let stone500 = SwiftUI.Color(light: "#8a8f97")
        /// Stone ramp (OKLCH hue 258°, cool on purpose so food photography supplies the warmth). Ramp step — views consume the semantic roles, not this.
        /// tokens.json: light `#6b7178` · dark `#6b7178`
        static let stone600 = SwiftUI.Color(light: "#6b7178")
        /// Stone ramp (OKLCH hue 258°, cool on purpose so food photography supplies the warmth). Ramp step — views consume the semantic roles, not this.
        /// tokens.json: light `#4d525a` · dark `#4d525a`
        static let stone700 = SwiftUI.Color(light: "#4d525a")
        /// Stone ramp (OKLCH hue 258°, cool on purpose so food photography supplies the warmth). Ramp step — views consume the semantic roles, not this.
        /// tokens.json: light `#31363c` · dark `#31363c`
        static let stone800 = SwiftUI.Color(light: "#31363c")
        /// Stone ramp (OKLCH hue 258°, cool on purpose so food photography supplies the warmth). Ramp step — views consume the semantic roles, not this.
        /// tokens.json: light `#1c2026` · dark `#1c2026`
        static let stone900 = SwiftUI.Color(light: "#1c2026")
        /// Stone ramp (OKLCH hue 258°, cool on purpose so food photography supplies the warmth). Ramp step — views consume the semantic roles, not this.
        /// tokens.json: light `#0f1217` · dark `#0f1217`
        static let stone950 = SwiftUI.Color(light: "#0f1217")
        /// Stone ramp (OKLCH hue 258°, cool on purpose so food photography supplies the warmth). Ramp step — views consume the semantic roles, not this.
        /// tokens.json: light `#06080c` · dark `#06080c`
        static let stone1000 = SwiftUI.Color(light: "#06080c")
        /// Pine ramp (hue 193°, chroma ≤ 0.086 — 128° from the oak table in the photos). Ramp step behind `accent*` roles; DividedScoreCard uses pine-600 / pine-400 directly.
        /// tokens.json: light `#ecf9f8` · dark `#ecf9f8`
        static let pine50 = SwiftUI.Color(light: "#ecf9f8")
        /// Pine ramp (hue 193°, chroma ≤ 0.086 — 128° from the oak table in the photos). Ramp step behind `accent*` roles; DividedScoreCard uses pine-600 / pine-400 directly.
        /// tokens.json: light `#d7f2f0` · dark `#d7f2f0`
        static let pine100 = SwiftUI.Color(light: "#d7f2f0")
        /// Pine ramp (hue 193°, chroma ≤ 0.086 — 128° from the oak table in the photos). Ramp step behind `accent*` roles; DividedScoreCard uses pine-600 / pine-400 directly.
        /// tokens.json: light `#b5e4e2` · dark `#b5e4e2`
        static let pine200 = SwiftUI.Color(light: "#b5e4e2")
        /// Pine ramp (hue 193°, chroma ≤ 0.086 — 128° from the oak table in the photos). Ramp step behind `accent*` roles; DividedScoreCard uses pine-600 / pine-400 directly.
        /// tokens.json: light `#87ccca` · dark `#87ccca`
        static let pine300 = SwiftUI.Color(light: "#87ccca")
        /// Pine ramp (hue 193°, chroma ≤ 0.086 — 128° from the oak table in the photos). Ramp step behind `accent*` roles; DividedScoreCard uses pine-600 / pine-400 directly.
        /// tokens.json: light `#4aa3a0` · dark `#4aa3a0`
        static let pine400 = SwiftUI.Color(light: "#4aa3a0")
        /// Pine ramp (hue 193°, chroma ≤ 0.086 — 128° from the oak table in the photos). Ramp step behind `accent*` roles; DividedScoreCard uses pine-600 / pine-400 directly.
        /// tokens.json: light `#07817f` · dark `#07817f`
        static let pine500 = SwiftUI.Color(light: "#07817f")
        /// Pine ramp (hue 193°, chroma ≤ 0.086 — 128° from the oak table in the photos). Ramp step behind `accent*` roles; DividedScoreCard uses pine-600 / pine-400 directly.
        /// tokens.json: light `#0a6867` · dark `#0a6867`
        static let pine600 = SwiftUI.Color(light: "#0a6867")
        /// Pine ramp (hue 193°, chroma ≤ 0.086 — 128° from the oak table in the photos). Ramp step behind `accent*` roles; DividedScoreCard uses pine-600 / pine-400 directly.
        /// tokens.json: light `#055150` · dark `#055150`
        static let pine700 = SwiftUI.Color(light: "#055150")
        /// Pine ramp (hue 193°, chroma ≤ 0.086 — 128° from the oak table in the photos). Ramp step behind `accent*` roles; DividedScoreCard uses pine-600 / pine-400 directly.
        /// tokens.json: light `#013b3a` · dark `#013b3a`
        static let pine800 = SwiftUI.Color(light: "#013b3a")
        /// Pine ramp (hue 193°, chroma ≤ 0.086 — 128° from the oak table in the photos). Ramp step behind `accent*` roles; DividedScoreCard uses pine-600 / pine-400 directly.
        /// tokens.json: light `#002a29` · dark `#002a29`
        static let pine900 = SwiftUI.Color(light: "#002a29")
    }

    /// `spacing` — 25 tokens, in points (rem × 16).
    /// Tailwind’s spacing scale: step N = N × 0.25rem (Tailwind `p-4`, `gap-7`, `h-11`…). Dots are escaped in CSS: var(--spacing-2\.5).
    enum Spacing {
        /// 2px.
        /// tokens.json: `spacing-0.5` = `0.125rem`
        static let s0_5: CGFloat = 2
        /// 4px. Icon–label gap in badges.
        /// tokens.json: `spacing-1` = `0.25rem`
        static let s1: CGFloat = 4
        /// 6px.
        /// tokens.json: `spacing-1.5` = `0.375rem`
        static let s1_5: CGFloat = 6
        /// 8px. Tight gaps; section label inset; chip side padding.
        /// tokens.json: `spacing-2` = `0.5rem`
        static let s2: CGFloat = 8
        /// 10px.
        /// tokens.json: `spacing-2.5` = `0.625rem`
        static let s2_5: CGFloat = 10
        /// 12px. Control gaps, row gaps.
        /// tokens.json: `spacing-3` = `0.75rem`
        static let s3: CGFloat = 12
        /// 14px.
        /// tokens.json: `spacing-3.5` = `0.875rem`
        static let s3_5: CGFloat = 14
        /// 16px. Screen gutter; card padding in lists; standard gap.
        /// tokens.json: `spacing-4` = `1rem`
        static let s4: CGFloat = 16
        /// 20px. Content-card padding (score, note, sheet cards); xl button side padding.
        /// tokens.json: `spacing-5` = `1.25rem`
        static let s5: CGFloat = 20
        /// 24px. Section gaps inside a sheet.
        /// tokens.json: `spacing-6` = `1.5rem`
        static let s6: CGFloat = 24
        /// 28px. Gap between blocks on a detail screen.
        /// tokens.json: `spacing-7` = `1.75rem`
        static let s7: CGFloat = 28
        /// 32px. Gap between major sections.
        /// tokens.json: `spacing-8` = `2rem`
        static let s8: CGFloat = 32
        /// 36px. sm control height (AppButton, Input); row score column.
        /// tokens.json: `spacing-9` = `2.25rem`
        static let s9: CGFloat = 36
        /// 40px.
        /// tokens.json: `spacing-10` = `2.5rem`
        static let s10: CGFloat = 40
        /// 44px. md control height; IconButton (the 44px touch minimum).
        /// tokens.json: `spacing-11` = `2.75rem`
        static let s11: CGFloat = 44
        /// 48px. xl control height (screen-bottom buttons).
        /// tokens.json: `spacing-12` = `3rem`
        static let s12: CGFloat = 48
        /// 56px. Minimum list-row height.
        /// tokens.json: `spacing-14` = `3.5rem`
        static let s14: CGFloat = 56
        /// 64px.
        /// tokens.json: `spacing-16` = `4rem`
        static let s16: CGFloat = 64
        /// 80px. Recipe thumbnail; large avatar.
        /// tokens.json: `spacing-20` = `5rem`
        static let s20: CGFloat = 80
        /// 96px.
        /// tokens.json: `spacing-24` = `6rem`
        static let s24: CGFloat = 96
        /// 112px. Add photo tile width.
        /// tokens.json: `spacing-28` = `7rem`
        static let s28: CGFloat = 112
        /// 144px. Narrow photo / timeline tile width.
        /// tokens.json: `spacing-36` = `9rem`
        static let s36: CGFloat = 144
        /// 192px. Timeline tile height.
        /// tokens.json: `spacing-48` = `12rem`
        static let s48: CGFloat = 192
        /// 256px. Wide hero photo width.
        /// tokens.json: `spacing-64` = `16rem`
        static let s64: CGFloat = 256
        /// 288px. Hero photo height.
        /// tokens.json: `spacing-72` = `18rem`
        static let s72: CGFloat = 288
    }

    /// `radius` — 8 tokens, in points (rem × 16; `full` is 9999).
    /// Tailwind v4 radius scale.
    enum Radius {
        /// 4px: grabber, progress track ends.
        /// tokens.json: `radius-sm` = `0.25rem`
        static let sm: CGFloat = 4
        /// 6px.
        /// tokens.json: `radius-md` = `0.375rem`
        static let md: CGFloat = 6
        /// 8px: compact score boxes, picker cells.
        /// tokens.json: `radius-lg` = `0.5rem`
        static let lg: CGFloat = 8
        /// 12px: inputs, recipe thumbnails, photo chips.
        /// tokens.json: `radius-xl` = `0.75rem`
        static let xl: CGFloat = 12
        /// 16px: timeline tiles and photos inside a list.
        /// tokens.json: `radius-2xl` = `1rem`
        static let xl2: CGFloat = 16
        /// 24px: cards, list cards, hero photos, the score card.
        /// tokens.json: `radius-3xl` = `1.5rem`
        static let xl3: CGFloat = 24
        /// 32px: top corners of a bottom sheet.
        /// tokens.json: `radius-4xl` = `2rem`
        static let xl4: CGFloat = 32
        /// Buttons, chips, pills, badges, avatars — every capsule.
        /// tokens.json: `radius-full` = `9999px`
        static let full: CGFloat = 9999
    }

    /// `opacity` — 16 tokens, in 0–1.
    /// Tailwind’s opacity scale.
    enum Opacity {
        /// tokens.json: `opacity-0` = `0`
        static let o0: Double = 0
        /// tokens.json: `opacity-5` = `0.05`
        static let o5: Double = 0.05
        /// Tinted card start, reaction-picker initial disc (fill mixed at 10%).
        /// tokens.json: `opacity-10` = `0.1`
        static let o10: Double = 0.1
        /// Reaction badge grounds (fill at 15%).
        /// tokens.json: `opacity-15` = `0.15`
        static let o15: Double = 0.15
        /// Selected ReactionPicker / TasteScoreSelector cell ground.
        /// tokens.json: `opacity-20` = `0.2`
        static let o20: Double = 0.2
        /// tokens.json: `opacity-25` = `0.25`
        static let o25: Double = 0.25
        /// Hairline strength of `line` on cards and fields; badge value divider.
        /// tokens.json: `opacity-30` = `0.3`
        static let o30: Double = 0.3
        /// tokens.json: `opacity-40` = `0.4`
        static let o40: Double = 0.4
        /// Disabled buttons and fields.
        /// tokens.json: `opacity-50` = `0.5`
        static let o50: Double = 0.5
        /// tokens.json: `opacity-60` = `0.6`
        static let o60: Double = 0.6
        /// Pressed button (with scale 0.985, 120ms ease-out).
        /// tokens.json: `opacity-70` = `0.7`
        static let o70: Double = 0.7
        /// tokens.json: `opacity-75` = `0.75`
        static let o75: Double = 0.75
        /// Focus and error borders.
        /// tokens.json: `opacity-80` = `0.8`
        static let o80: Double = 0.8
        /// tokens.json: `opacity-90` = `0.9`
        static let o90: Double = 0.9
        /// tokens.json: `opacity-95` = `0.95`
        static let o95: Double = 0.95
        /// tokens.json: `opacity-100` = `1`
        static let o100: Double = 1
    }

    /// `container` — 3 tokens, in points (rem × 16).
    /// Tailwind container widths.
    enum Container {
        /// 384px: phone-width content column.
        /// tokens.json: `container-sm` = `24rem`
        static let sm: CGFloat = 384
        /// 768px: web prose measure.
        /// tokens.json: `container-3xl` = `48rem`
        static let xl3: CGFloat = 768
        /// 1024px: web page container.
        /// tokens.json: `container-5xl` = `64rem`
        static let xl5: CGFloat = 1024
    }

    /// `text` — 10 tokens, in font size in points (rem × 16).
    /// Tailwind’s font-size scale, sizes only. Line height is its own scale (`leading-*`); every style pairs one size with one leading step.
    enum Text {
        /// Tailwind text-xs (12px).
        /// tokens.json: `text-xs` = `0.75rem`
        static let xs: CGFloat = 12
        /// Tailwind text-sm (14px).
        /// tokens.json: `text-sm` = `0.875rem`
        static let sm: CGFloat = 14
        /// Tailwind text-base (16px).
        /// tokens.json: `text-base` = `1rem`
        static let base: CGFloat = 16
        /// Tailwind text-lg (18px).
        /// tokens.json: `text-lg` = `1.125rem`
        static let lg: CGFloat = 18
        /// Tailwind text-xl (20px).
        /// tokens.json: `text-xl` = `1.25rem`
        static let xl: CGFloat = 20
        /// Tailwind text-2xl (24px).
        /// tokens.json: `text-2xl` = `1.5rem`
        static let xl2: CGFloat = 24
        /// Tailwind text-3xl (30px).
        /// tokens.json: `text-3xl` = `1.875rem`
        static let xl3: CGFloat = 30
        /// Tailwind text-4xl (36px).
        /// tokens.json: `text-4xl` = `2.25rem`
        static let xl4: CGFloat = 36
        /// Tailwind text-5xl (48px).
        /// tokens.json: `text-5xl` = `3rem`
        static let xl5: CGFloat = 48
        /// Tailwind text-6xl (60px).
        /// tokens.json: `text-6xl` = `3.75rem`
        static let xl6: CGFloat = 60
    }

    /// `font-weight` — 2 tokens, in CSS numeric weight.
    /// Only two weights exist.
    enum FontWeight {
        /// Everything by default; all Newsreader.
        /// tokens.json: `font-weight-normal` = `400`
        static let normal: Int = 400
        /// Sans only: buttons, headlines, chips and badges.
        /// tokens.json: `font-weight-semibold` = `600`
        static let semibold: Int = 600
    }

    /// `tracking` — 2 tokens, in em — multiply by the font size for points.
    /// Tailwind letter-spacing scale.
    enum Tracking {
        /// Large serif display (the cover name).
        /// tokens.json: `tracking-tight` = `-0.025em`
        static let tight: CGFloat = -0.025
        /// Uppercase overlines: section headers, card kind labels.
        /// tokens.json: `tracking-widest` = `0.1em`
        static let widest: CGFloat = 0.1
    }

    /// `leading` — 5 tokens, in line height as a multiple of the font size.
    /// Tailwind’s line-height scale, independent of size.
    enum Leading {
        /// serif-xl (numerals), chips, icon rows.
        /// tokens.json: `leading-none` = `1`
        static let none: CGFloat = 1
        /// serif-md and serif-lg (display titles).
        /// tokens.json: `leading-tight` = `1.25`
        static let tight: CGFloat = 1.25
        /// serif-xs and serif-sm (card titles, quotes, row scores).
        /// tokens.json: `leading-snug` = `1.375`
        static let snug: CGFloat = 1.375
        /// Every sans style (xs–xl).
        /// tokens.json: `leading-normal` = `1.5`
        static let normal: CGFloat = 1.5
        /// Long reading text on the web.
        /// tokens.json: `leading-relaxed` = `1.625`
        static let relaxed: CGFloat = 1.625
    }

    /// `border-width` — 2 tokens, in points.
    /// Border and ring widths. The only widths the system draws; nothing uses a raw px.
    enum BorderWidth {
        /// Dividers, card hairlines, a field at rest. Never 0.5px: a sub-pixel border renders as a blend and loses its contrast.
        /// tokens.json: `border-hairline` = `1px`
        static let hairline: CGFloat = 1
        /// A state worth noticing: focus ring, error border, selected ring.
        /// tokens.json: `border-thick` = `2px`
        static let thick: CGFloat = 2
    }

    /// `shadow` — 7 tokens, parsed from CSS box-shadow lists into layers.
    /// Tailwind v4 shadow scale in light. Cards carry none; only floating things do. In dark a black shadow can’t show on a near-black ground, so each dark value leads with a 1px white ring and a top highlight.
    enum Shadow {
        /// Hairline lift.
        static let xs2 = ShadowToken(
            // light: 0 1px rgba(0, 0, 0, 0.05)
            light: [
                ShadowLayer(x: 0, y: 1, blur: 0, spread: 0, color: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.05), inset: false),
            ],
            // dark: 0 0 0 1px rgba(255, 255, 255, 0.06)
            dark: [
                ShadowLayer(x: 0, y: 0, blur: 0, spread: 1, color: SwiftUI.Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.06), inset: false),
            ]
        )
        /// Elevated buttons and badges (floating over content).
        static let xs = ShadowToken(
            // light: 0 1px 2px 0 rgba(0, 0, 0, 0.05)
            light: [
                ShadowLayer(x: 0, y: 1, blur: 2, spread: 0, color: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.05), inset: false),
            ],
            // dark: 0 0 0 1px rgba(255, 255, 255, 0.1), inset 0 1px 0 rgba(255, 255, 255, 0.05), 0 1px 2px rgba(0, 0, 0, 0.6)
            dark: [
                ShadowLayer(x: 0, y: 0, blur: 0, spread: 1, color: SwiftUI.Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.1), inset: false),
                ShadowLayer(x: 0, y: 1, blur: 0, spread: 0, color: SwiftUI.Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.05), inset: true),
                ShadowLayer(x: 0, y: 1, blur: 2, spread: 0, color: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.6), inset: false),
            ]
        )
        /// Raised tiles (TasteScoreSelector).
        static let sm = ShadowToken(
            // light: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1)
            light: [
                ShadowLayer(x: 0, y: 1, blur: 3, spread: 0, color: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1), inset: false),
                ShadowLayer(x: 0, y: 1, blur: 2, spread: -1, color: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1), inset: false),
            ],
            // dark: 0 0 0 1px rgba(255, 255, 255, 0.08), inset 0 1px 0 rgba(255, 255, 255, 0.05), 0 1px 3px rgba(0, 0, 0, 0.6)
            dark: [
                ShadowLayer(x: 0, y: 0, blur: 0, spread: 1, color: SwiftUI.Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.08), inset: false),
                ShadowLayer(x: 0, y: 1, blur: 0, spread: 0, color: SwiftUI.Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.05), inset: true),
                ShadowLayer(x: 0, y: 1, blur: 3, spread: 0, color: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.6), inset: false),
            ]
        )
        /// Menus.
        static let md = ShadowToken(
            // light: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1)
            light: [
                ShadowLayer(x: 0, y: 4, blur: 6, spread: -1, color: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1), inset: false),
                ShadowLayer(x: 0, y: 2, blur: 4, spread: -2, color: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1), inset: false),
            ],
            // dark: 0 0 0 1px rgba(255, 255, 255, 0.08), inset 0 1px 0 rgba(255, 255, 255, 0.05), 0 4px 8px rgba(0, 0, 0, 0.6)
            dark: [
                ShadowLayer(x: 0, y: 0, blur: 0, spread: 1, color: SwiftUI.Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.08), inset: false),
                ShadowLayer(x: 0, y: 1, blur: 0, spread: 0, color: SwiftUI.Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.05), inset: true),
                ShadowLayer(x: 0, y: 4, blur: 8, spread: 0, color: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.6), inset: false),
            ]
        )
        /// Popovers, dragged cards.
        static let lg = ShadowToken(
            // light: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1)
            light: [
                ShadowLayer(x: 0, y: 10, blur: 15, spread: -3, color: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1), inset: false),
                ShadowLayer(x: 0, y: 4, blur: 6, spread: -4, color: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1), inset: false),
            ],
            // dark: 0 0 0 1px rgba(255, 255, 255, 0.1), inset 0 1px 0 rgba(255, 255, 255, 0.05), 0 10px 20px rgba(0, 0, 0, 0.7)
            dark: [
                ShadowLayer(x: 0, y: 0, blur: 0, spread: 1, color: SwiftUI.Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.1), inset: false),
                ShadowLayer(x: 0, y: 1, blur: 0, spread: 0, color: SwiftUI.Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.05), inset: true),
                ShadowLayer(x: 0, y: 10, blur: 20, spread: 0, color: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.7), inset: false),
            ]
        )
        /// Modal cards.
        static let xl = ShadowToken(
            // light: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1)
            light: [
                ShadowLayer(x: 0, y: 20, blur: 25, spread: -5, color: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1), inset: false),
                ShadowLayer(x: 0, y: 8, blur: 10, spread: -6, color: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1), inset: false),
            ],
            // dark: 0 0 0 1px rgba(255, 255, 255, 0.1), inset 0 1px 0 rgba(255, 255, 255, 0.05), 0 20px 30px rgba(0, 0, 0, 0.7)
            dark: [
                ShadowLayer(x: 0, y: 0, blur: 0, spread: 1, color: SwiftUI.Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.1), inset: false),
                ShadowLayer(x: 0, y: 1, blur: 0, spread: 0, color: SwiftUI.Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.05), inset: true),
                ShadowLayer(x: 0, y: 20, blur: 30, spread: 0, color: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.7), inset: false),
            ]
        )
        /// Full overlays.
        static let xl2 = ShadowToken(
            // light: 0 25px 50px -12px rgba(0, 0, 0, 0.25)
            light: [
                ShadowLayer(x: 0, y: 25, blur: 50, spread: -12, color: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.25), inset: false),
            ],
            // dark: 0 0 0 1px rgba(255, 255, 255, 0.12), inset 0 1px 0 rgba(255, 255, 255, 0.05), 0 25px 50px rgba(0, 0, 0, 0.8)
            dark: [
                ShadowLayer(x: 0, y: 0, blur: 0, spread: 1, color: SwiftUI.Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.12), inset: false),
                ShadowLayer(x: 0, y: 1, blur: 0, spread: 0, color: SwiftUI.Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.05), inset: true),
                ShadowLayer(x: 0, y: 25, blur: 50, spread: 0, color: SwiftUI.Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.8), inset: false),
            ]
        )
    }

    /// `motion` — 8 tokens. Durations in seconds; scales as multipliers; easing as
    /// the CSS keyword (map it to an `Animation` in hand-written code).
    /// Durations, easing and press scales. Every transition in the system uses one of these.
    enum Motion {
        /// Press feedback: opacity and the press scale.
        /// tokens.json: `duration-press` = `120ms`
        static let durationPress: Double = 0.12
        /// A state changing in place: a field's border, an icon's colour.
        /// tokens.json: `duration-state` = `150ms`
        static let durationState: Double = 0.15
        /// Something moving or resizing: the Add photo label collapsing, a bar's fill.
        /// tokens.json: `duration-layout` = `250ms`
        static let durationLayout: Double = 0.25
        /// One sweep of a Skeleton's shimmer. The only motion that loops; Reduce Motion stops it.
        /// tokens.json: `duration-shimmer` = `1400ms`
        static let durationShimmer: Double = 1.4
        /// The one easing curve.
        /// tokens.json: `ease-standard` = `ease-out`
        static let easeStandard: String = "ease-out"
        /// A pressed button, card or tile.
        /// tokens.json: `scale-press` = `0.985`
        static let scalePress: CGFloat = 0.985
        /// A pressed row — wider than it is tall, so it needs less.
        /// tokens.json: `scale-press-row` = `0.995`
        static let scalePressRow: CGFloat = 0.995
        /// A pressed Toggle knob, which scales instead of fading.
        /// tokens.json: `scale-knob` = `0.92`
        static let scaleKnob: CGFloat = 0.92
    }

    /// `type.families` — the CSS stacks, and the bundled font each resolves to on iOS.
    /// PostScript names are read from the .ttf files `type.fonts` lists (bundled in
    /// `Core/Fonts/`). `nil` means the platform system font (SF Pro).
    enum Font {
        /// tokens.json `sans`: -apple-system, BlinkMacSystemFont, "SF Pro Text", system-ui, "Segoe UI", Roboto, Helvetica, Arial, sans-serif
        static let sans: String? = nil
        static let sansItalic: String? = nil
        /// tokens.json `serif`: "Newsreader", Georgia, serif
        static let serif: String? = "Newsreader16pt-Regular"
        static let serifItalic: String? = "Newsreader16pt-Italic"
        /// tokens.json `serif-display`: "Newsreader Display", "Newsreader", Georgia, serif
        static let serifDisplay: String? = "Newsreader72pt-Regular"
        static let serifDisplayItalic: String? = nil
    }

    /// The font family a type style is set in (`type.families` keys).
    enum FontFamily: String, CaseIterable {
        case sans = "sans"
        case serif = "serif"
        case serifDisplay = "serif-display"

        /// PostScript name of the upright cut; `nil` = system font.
        var postScriptName: String? {
            switch self {
            case .sans: return Font.sans
            case .serif: return Font.serif
            case .serifDisplay: return Font.serifDisplay
            }
        }

        /// PostScript name of the italic cut, when the family bundles one.
        var italicPostScriptName: String? {
            switch self {
            case .sans: return Font.sansItalic
            case .serif: return Font.serifItalic
            case .serifDisplay: return Font.serifDisplayItalic
            }
        }
    }

    /// One step of the type scale: a family, a `text-*` size, a `leading-*` step and a
    /// weight, plus the iOS text style it scales with (README "Dynamic Type").
    struct TypeStyle {
        let name: String
        let family: FontFamily
        let size: CGFloat
        let lineHeight: CGFloat
        let weight: Int
        let relativeTo: SwiftUI.Font.TextStyle
    }

    /// `type.groups` — 10 styles.
    enum TypeStyles {
        /// Serif: Newsreader Regular, upright. md and up use the 72pt optical cut. Five steps, xs–xl. Italic is a separate axis, not a step.
        /// text-xl · leading-snug. Row scores, photo-chip scores, the cook’s note (which sets italic itself).
        static let serifXs = TypeStyle(
            name: "serif-xs", family: .serif,
            size: Text.xl, lineHeight: Leading.snug, weight: FontWeight.normal,
            relativeTo: .title3
        )
        /// text-2xl · leading-snug. Card titles, recipe names, the verdict beside a numeral.
        static let serifSm = TypeStyle(
            name: "serif-sm", family: .serif,
            size: Text.xl2, lineHeight: Leading.snug, weight: FontWeight.normal,
            relativeTo: .title2
        )
        /// text-3xl · leading-tight. Sheet verdicts, large openers.
        static let serifMd = TypeStyle(
            name: "serif-md", family: .serifDisplay,
            size: Text.xl3, lineHeight: Leading.tight, weight: FontWeight.normal,
            relativeTo: .title
        )
        /// text-4xl · leading-tight. Page and hero titles.
        static let serifLg = TypeStyle(
            name: "serif-lg", family: .serifDisplay,
            size: Text.xl4, lineHeight: Leading.tight, weight: FontWeight.normal,
            relativeTo: .largeTitle
        )
        /// text-5xl · leading-none. The score numeral, tabular, `primary-text`.
        static let serifXl = TypeStyle(
            name: "serif-xl", family: .serifDisplay,
            size: Text.xl5, lineHeight: Leading.none, weight: FontWeight.normal,
            relativeTo: .largeTitle
        )
        /// Sans: System sans. Every step is regular (400); weight is a separate axis — `font-weight-semibold` on buttons, badges and titles. Five steps, xs–xl, all leading-normal.
        /// text-xs · leading-normal. Card labels, provenance, chips and badges; uppercase + tracking-widest for section headers and kind labels.
        static let sansXs = TypeStyle(
            name: "sans-xs", family: .sans,
            size: Text.xs, lineHeight: Leading.normal, weight: FontWeight.normal,
            relativeTo: .caption
        )
        /// text-sm · leading-normal. Meta, dates, counts, row notes, reason detail, sm buttons.
        static let sansSm = TypeStyle(
            name: "sans-sm", family: .sans,
            size: Text.sm, lineHeight: Leading.normal, weight: FontWeight.normal,
            relativeTo: .footnote
        )
        /// text-base · leading-normal. Body, row labels, input text, md buttons.
        static let sansMd = TypeStyle(
            name: "sans-md", family: .sans,
            size: Text.base, lineHeight: Leading.normal, weight: FontWeight.normal,
            relativeTo: .body
        )
        /// text-lg · leading-normal. xl buttons, sheet and reason titles, change badges — all of which set semibold themselves.
        static let sansLg = TypeStyle(
            name: "sans-lg", family: .sans,
            size: Text.lg, lineHeight: Leading.normal, weight: FontWeight.normal,
            relativeTo: .body
        )
        /// text-xl · leading-normal. TasteScoreSelector numerals, large sans figures.
        static let sansXl = TypeStyle(
            name: "sans-xl", family: .sans,
            size: Text.xl, lineHeight: Leading.normal, weight: FontWeight.normal,
            relativeTo: .title3
        )

        static let all: [TypeStyle] = [serifXs, serifSm, serifMd, serifLg, serifXl, sansXs, sansSm, sansMd, sansLg, sansXl]
    }
}
