# Core/Design: design tokens

The design system is the only source of values in the app. No view invents a size,
spacing, colour, radius, shadow, opacity or duration. This folder turns the vendored
spec into Swift names.

## How tokens flow

```
design-system/tokens.json  ──┐
design-system/README.md    ──┼─> scripts/ds-tokens-swift.py ─> Generated/DSTokens.generated.swift
Core/Fonts/*.ttf           ──┘                                        │
                                                                      v
                                  DS+Color / DS+Spacing / DS+Radius / DS+Shadow / DS+Opacity /
                                  DS+Typography / DS+Motion / DS+Palette  (aliases only)
                                                                      │
                                                                      v
                                          Core/Components  ->  Features
```

- `design-system/` (repo root) is a vendored snapshot of the artifact named in
  `design-system/VERSION`. Never hand-edit it: change the artifact, then re-vendor.
- `Generated/DSTokens.generated.swift` is written by the generator. Never hand-edit it.
  The generator also reads the README "Dynamic Type" table (step to iOS text style) and
  the PostScript names of the bundled Newsreader cuts.
- The `DS+*.swift` files only give generated values their Swift names. No literal lives
  there.
- Views use the `DS.*` roles and `.textStyle(...)`. They never use `DSTokens` or the
  Stone/Pine ramps (`DS+Palette`) directly.

## Updating the design system

0. To change the system, edit the artifact first (https://claude.ai/artifact/4jeEJ91V5eRxpDn8NtqNgK, files under `project/`; its `SKILL.md` lists the file shapes). Read the live files right before writing: other people edit it too.
1. Download the artifact's `project/` files into `design-system/` (skip the generated `manifest.json` and `preview.html` files) and set `VERSION` to the artifact's version.
2. Run `python3 scripts/ds-tokens-swift.py`. The output is deterministic. An unknown token
   family or an unresolvable alias fails the run; it is never guessed.
3. Build, then run `scripts/ds-lint.sh`. Fix renamed or removed tokens at the call sites.
4. Re-read the changed `design-system/components/*/README.md` files against
   `Core/Components`. A contradiction is fixed in the artifact's README, not worked around in Swift.

## Platform notes

Values iOS has to draw that the spec leaves open. Each is a call, not a gap: the spec is
right and the platform just has no token for it.

| README text | iOS draws |
| --- | --- |
| BottomSheet: "`scrim` behind" | The system sheet dimming (SwiftUI exposes no colour) |
| BottomSheet grabber | `radius-sm`, `spacing-2` from the top; the system indicator's VoiceOver resize action is lost |
| TasteScoreSelector: "a 1.5px fill ring" | `border-thick` (tokens.json: "selected ring") |
| TasteScoreSelector: "Spring 0.25 / 0.75" and the root "Selection springs" | The README values, quoted in code; `.spring(duration: duration-layout)` for selections |
| Toggle: "Pressing scales the knob" | `duration-state` for slide and scale |
| PhotoCard: "`portrait` and `landscape` are both 3:4" | `shortEdgeRatio = 3/4` (`ds-lint:allow`); xs portrait 60 and lg portrait 216 fall off the spacing scale |
| PhotoScrim / "Imagery": `stone-1000` at 72%, clear at 32% | The quoted values (`ds-lint:allow`) |
| Photo overlays (white on photo) | `stone-0`, the ramp step under the `stone-1000` scrim |
| Input: "an alert glyph" | `exclamationmark.circle` at `sans-xs` |
| AppButton loading: spinner 1em | `ProgressView` `.mini` (xs, sm) / `.small` (md, lg) |
| ProCard locked preview cap | `spacing-28` |
| Bar chart index past `chart-series7` | `primary` ("A block with no `reaction` or `color` is `primary`") |
| RatingList row value: no step | `serif-xs` tabular (SegmentedBar rows), `sans-sm` in the general shape |
| Hover, focus ring with offset | Pointer-only rules; not drawn on iOS |
| Navigation bar title | `sans-lg` semibold inline (Typography: "sheet and reason titles"); the system draws the bar |
| Top-bar controls | A system toolbar button on the white glass circle via `.barItemStyle()` (BarButton README) |
| Sheet detents | `.dsSheet(detents:)`; a fitted sheet (Add photo) sizes to its content |

## Token names

| Spec token | Swift |
| --- | --- |
| `primary`, `primary-soft`, `primary-text`, `on-primary` | `DS.Color.primary`, `.primarySoft`, `.primaryText`, `.onPrimary` |
| `bg`, `panel`, `sunken`, `sheet`, `line`, `line-control` | `DS.Color.bg`, `.panel`, `.sunken`, `.sheet`, `.line`, `.lineControl` |
| `text-primary` / `-secondary` / `-tertiary` | `DS.Color.textPrimary` …, or `tone: .primary/.secondary/.tertiary` |
| `{role}` fill / soft / text / on (roles primary, secondary, destructive, pro, warning) | `DS.Role` |
| `spacing-4`, `spacing-2.5` | `DS.Spacing.s4`, `DS.Spacing.s2_5` |
| layout aliases | `DS.Spacing.gutter` (s4), `.block` (s7), `.cardPadding` (s5), `.sectionInset` (s2), `.rowMin` (s14), `.rowMinSm` (s11) |
| `radius-lg`, `radius-2xl`, `radius-full` | `DS.Radius.lg`, `.xl2`, `.full` |
| `shadow-xs`, `shadow-lg` | `.dsShadow(.xs)`, `.dsShadow(.lg)` (dark mode adds the ring and highlight) |
| `border-hairline`, `border-thick` | `DS.BorderWidth.hairline`, `.thick`; a `line` hairline ring is `.dsHairline()` |
| `opacity-70` | `DS.Opacity.o70` (`DS.Opacity.pressed` for the press state) |
| `duration-state`, `scale-press` | `DS.Motion.durationState`, `.scalePress`; animations `DS.Motion.press` / `.state` |
| `container-sm` | `DS.Container.sm` |
| `serif-lg`, `sans-sm` | `.textStyle(.serifLg)`, `.textStyle(.sansSm)` |
| `font-weight-semibold` | `.textStyle(.sansMd, weight: .semibold)`. Steps carry no weight of their own |
| `tracking-widest` | `DS.TextStyle.sansXs.trackingWidest` |

Type: `.textStyle(_:tone:weight:italic:numeric:lines:align:)` sets the font (Dynamic Type
through `relativeTo:`), line height and ink. There is no other way to set a font.

## Lint

`scripts/ds-lint.sh` fails on numeric literals other than 0 and 1 in font sizes, padding,
spacing, frames, radii, opacity, line widths and scales, and on colour literals and named
system colours. It scans `Core/Components`, `Core/Extensions`, `Core/Design` (except
`Generated/`) and `Features`. It must be clean before a merge. A line that has to keep a
literal ends in `// ds-lint:allow <reason>` quoting the README it came from; today that is
the `Color+Hex` hex parser, PhotoCard's 3:4 ratio and PhotoScrim's two "Imagery" stops.

`DesignTokensPreview.swift` shows every token in light and dark mode in Xcode previews.
