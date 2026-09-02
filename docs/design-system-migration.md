# NomNom — design system migration

Paste this whole file as the task prompt. It is self-contained.

---

You are working in **NomNom**, a SwiftUI iOS app (Xcode project `NomNom.xcodeproj`, Supabase backend). Your job is to introduce a real colour token layer and fix three encoding defects in the rating scales, in **six reviewable phases**, one commit per phase.

## Before you write anything

1. Read `AGENTS.md` and `.agents/rules/file-structure.md`. They govern file placement and conventions — follow them over any structure implied here.
2. Read `CONTEXT.md` and `docs/adr/0001-one-rating-per-user-per-meal.md`.
3. Read these, they are the surface you are changing:
   - `NomNom/Domain/Reaction.swift`, `NomNom/Domain/RatingAxes.swift`
   - `NomNom/Core/Components/TactileOptionPicker.swift` (defines `TactilePickerOption.tint`)
   - `NomNom/Core/Components/ReactionPicker.swift`, `TactileTasteSelector.swift`, `VerdictStrip.swift`, `RecipeVerdictBadge.swift`, `SectionCard.swift`, `Chip.swift`
   - `NomNom/Core/Extensions/AppRadius.swift`, `NomNom/Core/Fonts/Typography.swift`
   - `NomNom/Assets.xcassets/` (currently only `AppIcon` and `AccentColor`)
4. Build the project before you start and confirm it is green. Every phase must end green.

## Hard constraints — do not violate

- **Do not change `AppRadius.standard`.** The app is deliberately at 2pt. Radius is already a single-knob token system; leave it alone.
- **Do not swap the fonts.** Newsreader (serif display) + Inter (UI) are bundled and Dynamic-Type aware via `Font.newsreader(_:)` / `Font.inter(_:)`. Use that API; add nothing new to `Core/Fonts/`.
- **Do not change any `enum` raw values, `Codable` conformance, `score`, or `fromRaw`.** Persistence and the suggestion engine depend on them. No Supabase migrations in this task.
- **Do not change the emoji or SF Symbol per case** unless a phase says so explicitly.
- Never hard-code a hex or `Color(red:green:blue:)` in a view. Views read tokens only.
- Do not touch `supabase/`, `Services/`, or `Features/Suggestions/Engine/`.

## Why these changes (so you can make judgement calls)

The app's category photography is 14 shots that measure, across all of them, **oklch 0.65 / 0.065 / 65°** for the oak table and **0.74 / 0.073 / 66°** for the stoneware plate — hue spread under 9°. Three consequences drive everything below.

1. **Any UI colour in the 40–90° hue band disappears into the photos.** `EffortLevel.thirtyTo60` is currently `.orange` — 18° from the table.
2. **Taste steps are not separable.** Measured on the current tints, neighbouring steps sit at OKLab ΔE 0.051–0.056, and under deuteranopia simulation `bad` and `good` land at ΔE **0.010** — the same colour. The replacement ramp raises min neighbour ΔE to 0.082 and the worst deuteranope pair to 0.053.
3. **Ordinal scales encoded as hue don't encode order.** `EffortLevel` runs cyan → blue → orange → purple: not ordered in hue, lightness or chroma. It becomes a monochrome 4-segment meter. `RotationGoal` runs secondary → indigo → emerald: it becomes outline → tinted → filled in one hue.

Net: the app goes from **9 hues to 3** — one neutral ramp, one accent, one diverging rating ramp. Saturated colour comes to mean exactly one thing: how the food tasted.

`RotationGoal.staple` and `Reaction.amazing` are also currently near-identical greens (`emeraldGreen` vs `.green`). Phase 3 removes that collision.

---

# The token set

All values are sRGB hex, generated in OKLCH and contrast-verified. Hex is the source of truth.

## Stone — neutral ramp (hue 258°)

Cool on purpose. The photos supply all the warmth; a cream or beige shell would land within 10° of the stoneware and flatten every card into its own image.

| Step | Hex | Step | Hex |
|---|---|---|---|
| stone0 | `#FFFFFF` | stone500 | `#8A8F97` |
| stone25 | `#FAFBFC` | stone600 | `#6B7178` |
| stone50 | `#F5F7F9` | stone700 | `#4D525A` |
| stone100 | `#EFF1F4` | stone800 | `#31363C` |
| stone200 | `#E3E5E9` | stone900 | `#1C2026` |
| stone300 | `#D0D4D9` | stone950 | `#0F1217` |
| stone400 | `#ADB1B8` | stone1000 | `#06080C` |

## Pine — the single accent (hue 193°)

128° from the oak, so it never vanishes on a photo. Chroma held ≤ 0.086 so it stays clearly separate from rating chips, which run 0.125–0.170. **Low-chroma accent, high-chroma data** is the rule that stops brand colour and meaning colour being confused.

| Step | Hex | Step | Hex |
|---|---|---|---|
| pine50 | `#ECF9F8` | pine500 | `#07817F` |
| pine100 | `#D7F2F0` | pine600 | `#0A6867` |
| pine200 | `#B5E4E2` | pine700 | `#055150` |
| pine300 | `#87CCCA` | pine800 | `#013B3A` |
| pine400 | `#4AA3A0` | pine900 | `#002A29` |

## Semantic roles — these are what views use

| Role | Light | Dark | Use |
|---|---|---|---|
| `bg` | stone50 `#F5F7F9` | stone1000 `#06080C` | Screen ground |
| `panel` | stone0 `#FFFFFF` | stone950 `#0F1217` | Cards, sheets, nav bar |
| `sunken` | stone100 `#EFF1F4` | stone900 `#1C2026` | Inputs, chips, image placeholder |
| `line` | stone200 `#E3E5E9` | stone800 `#31363C` | Hairlines, card edges |
| `lineStrong` | stone300 `#D0D4D9` | stone700 `#4D525A` | Selected borders, dividers |
| `textPrimary` | stone900 `#1C2026` | stone100 `#EFF1F4` | Titles — 16.4:1 / 17.7:1 |
| `textSecondary` | stone700 `#4D525A` | stone300 `#D0D4D9` | Body — 7.9:1 / 13.5:1 |
| `textTertiary` | stone600 `#6B7178` | stone400 `#ADB1B8` | Meta, captions — 4.9:1 / 9.3:1 |
| `accent` | pine600 `#0A6867` | pine400 `#4AA3A0` | Primary action, active tab, filled meter |
| `accentText` | pine700 `#055150` | pine300 `#87CCCA` | Accent-coloured text |
| `accentSoft` | pine50 `#ECF9F8` | pine900 `#002A29` | Tinted accent background |

## Reaction — the only saturated colour in the app

Two roles per step. **`fill`** paints shapes; **`text`** is for `foregroundStyle`. The existing code uses `foregroundStyle(reaction.tint)` on light surfaces in ~15 places, and at fill chroma those fail AA — hence the separate text role.

| Case | Light fill | Light text | Dark fill + text | Glyph |
|---|---|---|---|---|
| `.inedible` (−1) | `#BF3A37` | `#A51E21` | `#E97970` | `xmark.circle.fill` |
| `.bad` (1) | `#D16633` | `#9B3400` | `#EE8E64` | `hand.thumbsdown.fill` |
| `.meh` (2) | `#D3A032` | `#774D00` | `#E4B65C` | `minus.circle.fill` |
| `.good` (3) | `#7BA853` | `#3C6211` | `#A0CA7F` | `hand.thumbsup` |
| `.great` (4) | `#2E985E` | `#006836` | `#71C791` | `hand.thumbsup.fill` |
| `.amazing` (5) | `#247F63` | `#00684C` | `#62BC9C` | `star.fill` |
| **unrated** (`nil`) | `sunken` | `textTertiary` | `sunken` / `textTertiary` | `circle.dashed` |

Light text role measures 6.8–7.5:1 on `panel` and 5.7–6.6:1 on a 14% fill tint. Dark measures 6.6–10.1:1 on `panel` and ≥5.1:1 on an 18% tint. In dark mode one value serves both roles.

**Rules for reaction colour**

- Solid fill never carries text. Selected state = `fill.opacity(0.14–0.20)` background + `text` foreground + 1.5pt `fill` border. This is already the `ReactionPicker` idiom — keep it.
- Every reaction chip renders its numeral or SF Symbol alongside the colour. A diverging ramp collapses at both ends in greyscale; colour is confirmation, never the message.
- Reaction colour appears only in the rating control and a single chip on a card. It never tints a card background, never colours body text, never appears behind photography.
- `nil` (not yet rated) is a real, defined state — most rows in a fresh install. It is neutral, not grey-by-accident.

---

# Phases

One commit each. Build green and screenshot-check light **and** dark before moving on.

## Phase 1 — Token layer

Create `NomNom/Core/Design/DesignTokens.swift` (place per `.agents/rules/file-structure.md` if it says otherwise).

- Add Color Sets to `Assets.xcassets` in a `Design/` group: the full Stone and Pine ramps as literal sRGB values, plus one Color Set per **semantic role** with `Any` and `Dark` appearances set to the light/dark values in the roles table. Semantic sets are what views consume; ramp sets exist so the roles are traceable.
- Expose them through a `DS` namespace:

```swift
enum DS {
    enum Color {
        static let bg = SwiftUI.Color("ds/bg")
        static let panel = SwiftUI.Color("ds/panel")
        // … one per semantic role
    }
}
```

- Point `AccentColor.colorset` at pine600 / pine400 so the ~11 `.foregroundStyle(.tint)` and 51 `Color.accentColor` call sites inherit the accent with no edits.
- Add a SwiftUI Preview that renders every ramp and every role side by side in both schemes. This is your regression surface for the rest of the migration.

**Done when:** the app builds, the accent has changed app-wide, and the preview shows both schemes correctly. No other visual change yet.

## Phase 2 — Reaction ramp

- Replace `Reaction.tint` with two properties: `fill: Color` and `text: Color`, both reading `DS` Color Sets (`ds/reaction/inedible/fill` etc.). Keep `tint` as a `@available(*, deprecated)` alias returning `fill` so nothing breaks mid-phase, then remove it at the end of the phase.
- Update the ~15 call sites: `foregroundStyle` takes `.text`, shape fills and borders take `.fill`. Files: `ReactionPicker.swift`, `TactileTasteSelector.swift`, `VerdictStrip.swift`, `RecipeVerdictBadge.swift`, `MealDetailPartyRatingsCard.swift`, `RecipeInsightView.swift`, `MyVerdictCard.swift`, `MealRatingSheet.swift`, `MealRatingBadge.swift`.
- `VerdictStrip.swift:41` currently falls back to `.gray.opacity(0.08)` for a `nil` reaction. Replace with the defined unrated treatment: `sunken` fill, `textTertiary` foreground, `circle.dashed` glyph.
- Ensure every place that shows a reaction colour also shows `numberLabel` or `systemImage`. Add the numeral where it is missing.
- Add `.accessibilityLabel(reaction.name)` to every reaction control and badge.

**Done when:** `grep -rn "reaction.tint" NomNom/` returns nothing, and no reaction is identifiable by colour alone anywhere in the app.

## Phase 3 — EffortLevel and RotationGoal lose their hues

- **Delete `EffortLevel.tint`.** Build `NomNom/Core/Components/BurnerMeter.swift`: four segments, widths 9pt, heights 7/12/17/22pt, corner radius 2 (`AppRadius.standard`), filled = `DS.Color.accent`, empty = `lineStrong`. `zeroTo15` fills 1, `over60` fills 4. A `nil` effort renders all-empty plus an em dash.
  Rising height means the meter still reads at 1-bit and in greyscale, and the ordinal claim is true by construction.
- **Delete `RotationGoal.tint` and the private `Color.emeraldGreen` extension** at the bottom of `RatingAxes.swift`. Rotation renders as pill weight in one hue: `oneAndDone` = outline (`lineStrong` border, `textTertiary` label), `sometimes` = `accentSoft` fill with `accentText` label, `staple` = `accent` fill with `panel` label.
- `TactilePickerOption.tint` is still required by the protocol and used by `TactileOptionPicker`. Give `EffortLevel` and `RotationGoal` a `tint` of `DS.Color.accent` so the generic picker keeps working, and have those two pickers render `BurnerMeter` / the weight pills in the option body rather than relying on hue.

**Done when:** no `.cyan`, `.blue`, `.orange`, `.purple`, `.indigo` or `emeraldGreen` remains in `RatingAxes.swift`, and effort/rotation are legible in a greyscale screenshot.

## Phase 4 — Imagery

Applies to `MealPhoto.swift`, `RemoteMealPhoto.swift`, `MealPhotoCardView.swift`, `MealDetailPhotoHeader.swift`, `RecipeRowCard.swift`.

- **Scrim.** Any text over a photo gets a bottom gradient: `rgba(6,8,12,0.72)` → transparent at 68% of height. Non-negotiable — the mean plate is L 0.74 and white on it is 1.6:1; with the scrim it is 5.8:1 over plate and 7.5:1 over table.
- **Crop.** Preserve the square master and crop from centre. Food occupies the middle ~70% in every shot, so 1:1 and 4:5 crop safely; **16:9 does not** — do not introduce it.
- **Radius.** `AppRadius.photo` as today. Do not round photos differently from everything else.
- **Placeholder.** `sunken` ground, dashed `line` border, a plate glyph, caption "No photo yet". Never a grey box, never a substitute photo.
- **Never** tint a photo with the accent or a reaction colour.
- **Category is never carried by the image alone.** At list-thumbnail size the 14 category shots are the same picture — same plate, same table, same crop. Every tile ships its text label.

## Phase 5 — Neutral migration

Mechanical and high-volume: ~150 call sites. Do it feature folder by feature folder, building between each.

| Replace | With |
|---|---|
| `.foregroundStyle(.primary)`, `Color.primary` | `DS.Color.textPrimary` |
| `.foregroundStyle(.secondary)`, `Color.secondary` | `DS.Color.textSecondary` |
| `.foregroundStyle(.tertiary)` | `DS.Color.textTertiary` |
| `Color(uiColor: .tertiarySystemFill)` | `DS.Color.sunken` |
| `Color(uiColor: .separator)` | `DS.Color.line` |
| screen/list backgrounds | `DS.Color.bg` |
| card/sheet backgrounds | `DS.Color.panel` |

Leave `.red` on destructive actions (`DangerZoneSection`) — that is a system convention, not a brand colour. Then set `AppTypography` / heading usage against the scale below; do not add fonts.

| Token | Face | Size / leading |
|---|---|---|
| displayXL | `Font.newsreader(size: 32, weight: .regular, relativeTo: .largeTitle)` | dish names, page titles |
| displayL | `Font.newsreader(.title2, weight: .semibold)` | section heroes |
| displayM | `Font.newsreader(.title3)` | card titles |
| bodyL / bodyM / bodyS | `Font.inter(.body)` / `.callout` / `.footnote` | prose, meta |
| label | `Font.inter(.caption, weight: .semibold)` + `.textCase(.uppercase)` + 0.09em tracking | field labels |
| data | `Font.inter(.callout)` + `.monospacedDigit()` | durations, counts, scores |

Every number that stacks in a column gets `.monospacedDigit()`.

## Phase 6 — Verification

- Screenshot every primary screen in light and dark, at default and at XXL Dynamic Type. Nothing clipped, nothing unreadable.
- Run a greyscale pass: reaction, effort and rotation must all still be readable.
- Honour `@Environment(\.accessibilityDifferentiateWithoutColor)` — when on, reaction chips show the numeral even in compact placements.
- Honour `@Environment(\.accessibilityReduceMotion)` — the rating-commit scale animation becomes opacity only.
- Confirm 44×44pt minimum on every rating step and pill.
- Focus/selection states visible on all interactive primitives.
- `grep -rn "Color(red:\|Color\.orange\|Color\.teal\|Color\.mint\|\.cyan\|\.indigo" NomNom/` returns only intentional survivors, listed in the commit message.

---

# Report back

When you finish, list: files changed per phase, any place where a token in this spec fought an existing convention in `AGENTS.md` (the repo convention wins — say where you deviated), and anything in the roles table that had no natural call site.
