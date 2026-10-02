# Design system v2: what changed and what it means for our code

Compares the OLD snapshot (the one Phases 1–3B were built against) with the NEW v2 snapshot, then checks it against `feat/design-system` @ `70c8fbfc` and the three unmerged Phase 4 branches. Read-only analysis; no code was changed.

**Short version:** v2 barely touches tokens (one new colour, three colour values, one type weight). Most of the change is in component rules: five interim components are now real DS components, `ProgressBar` is now `Bar`, `PendingInviteRow` is removed, `SectionCard` has a single layout, inputs have a single style, and no button is smaller than 44pt. Most of what we've built can be kept.

---

## 1. Token changes (tokens.json)

The token count goes from 213 to 214. Nothing was removed or renamed. Spacing, radius, shadow, opacity, container, tracking, leading and font-weight are **all unchanged**, and so are both palette ramps.

### Colour

| token | OLD light / dark | NEW light / dark | note |
| --- | --- | --- | --- |
| `line-control` | n/a | **`#7a8089` / `#7a8290`** | **Added.** Border of anything a person can press or type in (outline buttons, input hover, `oneAndDone` pill, scrollbar thumb). Reaches 3:1 or better on `panel`, `bg`, `sunken` and `sheet` in both themes. |
| `line-strong` | `#d5d8dc` / `stone-700` | same | Same value. Its usage is now limited to decorative lines only (Timeline rail and other rules), and it is deliberately below 3:1. |
| `destructive` | `#ff3b30` / `#ff453a` | **`#d93229` / `#d93b31`** | System red darkened 15%. White on it is now 4.73:1 (light) and 4.55:1 (dark). |
| `on-destructive` | `#ffffff` (single value) | `#ffffff` / `#ffffff` | The value is now an explicit light/dark pair. No visual change. |
| `on-primary` | `#ffffff` (light only) | `#ffffff` / **`{pine-900}` (`#002a29`)** | Solid primary in dark mode becomes dark ink on teal (5.16:1, where white was 2.98:1). |

### Type styles

| style | OLD | NEW |
| --- | --- | --- |
| `sans-lg` | 18px / 1.5, **fontWeight 600** | 18px / 1.5, **fontWeight 400**. Callers (lg buttons, sheet titles, change badges) now set semibold themselves. |
| `serif-xs` | usage said "the cook's note (italic)" | Italic is now a separate axis and no style is italic by default. The sample text changed. |
| group notes | "Regular by default; semibold for…" | "Every step is regular (400); weight is a separate axis" |

No type sizes, line heights, tracking or families changed. No new token families were added.

---

## 2. Global rule changes (README)

- **Colour**
  - New role: `line-control`. A line that carries meaning (a control border) uses `line-control`. `line-strong` is for decoration only.
  - `destructive` is darkened and `on-primary` in dark mode is `pine-900`. The "known contrast misses" list is gone; v2 claims every text pair reaches 4.5:1 and every control border 3:1.
- **Typography**
  - "Two faces, **two** weights" (previously three).
  - Every scale step is regular. Weight and italic are opt-in axes; no step brings its own weight.
- **Layout and controls**
  - **No button is drawn smaller than 44pt.** `xs`, `sm` and `md` are all 44 tall and differ only in type size and side padding. `lg` is 48. Toggle is the only control below 44pt.
  - Every icon-only button is a 44pt circle.
- **Composition (new rules)**
  - *Horizontal scrollers* are one shared thing (`.nn-scroller`): snapping, contained overscroll, and a `line-control` thumb on pointer devices.
  - ***A fact is not a status.*** Metadata such as duration, method or count is a `sans-sm text-tertiary` line joined with " · ", never a row of chips. Badges are for status: Staple, Pro, Archived, a verdict, New, a delta.
  - ***Lists*** are always `Card layout="list"` + `ListRow`. An empty list is replaced by `EmptyState`, never shown as an empty card.
- **Component catalogue**
  - Grows from 22 to 29 live components (33 exported symbols).
  - New primitives: `Bar`, `Toggle`.
  - New layout component: `PageHeader`.
  - New composites: `ListRow`, `EmptyState`, `SegmentedBar`, `ValueStepper`.
- **Still to design** (an explicit new section): TrendChart, MediaViewerSheet, PhotoStrip edit mode, LabeledPhotoCard, RecipeShelf, PartyCard, form blocks and step toolbars. These keep using `Interim/`.
- **Not changed:** motion, iconography, imagery, logo and the content/voice sections. The one exception is in Motion, see below.

**v2 contradicts itself in several places.** Raise these with the DS owner. Until then, follow the component README, which is the more specific source.

| where | stale text | conflicts with |
| --- | --- | --- |
| README, Motion | "Focused field: 1.5px primary at opacity-80" | Input README: 2px at full strength |
| README, axes table | "`xs` is the icon-only button that floats on a photo" | AppButton README: `xs` is a labelled size; icon-only buttons have one size |
| AppButton README | outline uses `line-strong` for secondary; the "known misses" contrast note | root README: `line-control`; no misses remain |
| Badge README, recipes table | "Metadata chip (diet, time, method)", "Rank" badge | DetailHeader and ListRow: facts are text, and a rank is `Text serif-xs`, never a Badge |
| DetailHeader rules | "Facts are Badges (`sm` icon allowed)" | the same README's "Facts are not badges" section |
| RatingList, SegmentedBar READMEs | "ProgressBar `xs`" / "a single filled proportion is ProgressBar" | ProgressBar is deprecated in favour of Bar |
| README, detail-screen composition | "note (SectionCard `inset`)" | SectionCard no longer has a `layout` |
| PhotoCard sizes | "all on the spacing scale" | 60pt (xs portrait) and 216pt (lg portrait) are not spacing tokens (no `spacing-15` or `spacing-54`) |
| Imagery | "1:1 and 4:5 are safe" crops | PhotoCard formats are 1:1 and 3:4; there is no 4:5 |

---

## 3. Component inventory (NEW compared with OLD)

| component | status | concrete differences |
| --- | --- | --- |
| Text | changed | `weight` defaults to `normal` at every step (`sans-lg` is no longer semibold). `italic` is its own prop and no step defaults to it. |
| AppButton | **changed** | Adds an **`xs`** size (44 tall, `spacing-2.5` padding, `sans-xs` semibold, gap `spacing-1`). **`sm` goes from 36 to 44** (padding `s3`, `sans-sm`). `md` is 44 and `lg` 48, unchanged. Minimum width and height are 44, and icon-only is always a 44pt circle. |
| Badge | changed (docs only) | New "what is and is not a badge" rule (two tests: would you scan a list for it, and could it be different tomorrow). API and sizes unchanged (sm 20, md 24). |
| Avatar | unchanged | none |
| Card | unchanged | none |
| Section | unchanged | none |
| SectionHeader | **changed** | **The `inset` prop is removed.** The header reserves no space; the parent (Section, Card) supplies padding. One label is used everywhere (eyebrow and head). `as`: `h2` above content, `span` inside a card. Rules: at most one trailing figure (never a button), and the title truncates before the figure. |
| SectionCard | **changed** | **`layout` (`stacked`/`inset`) is removed.** It is now only the label-inside-the-card shape. A label above the card is written as `Section` + `Card`. Adds `onClick`. The `primary` variant is kept. |
| PageHeader | **new** | `title`, `subtitle` (one sentence, `sans-md secondary`, capped at `container-sm`), `eyebrow`, `actions[]` (first `primary solid`, the rest `ghost`; `lg` at md and `md` at sm; at most 2), `align` start (default) or center, `size` sm (`serif-md`) or md (`serif-lg`), `children`. Replaces PageHeader and PageHeading. |
| ScoreValue | unchanged | none |
| ScoreCard | unchanged | Its README is unchanged; it now draws a Bar instead of ProgressBar. |
| Bar | **new** | `value`/`max` (single fill, `role=meter`), or `segments[{value, reaction?, color?, label?}]`. Sizes xs 4, sm 6, md 8, lg 10, xl 12. Segments are separated by a 1px `panel` seam, not a gap. `max` together with segments gives a part-empty bar. Uncoloured blocks are `primary`. A bar carries no text. |
| ProgressBar | **deprecated** | A single-fill Bar under the old name (`value`, `max`, `size`, `label`). |
| PhotoCard | **changed** | **New `format` axis** (square, portrait, landscape; 3:4) separate from `size`, which now means the long edge (xs 80, sm/md 192, lg 288). **lg portrait is 216×288, previously 256×288.** xs portrait is 60×80. **The favourite heart is now an AppButton `secondary elevated iconOnly` (44×44)**: an outlined heart when off, filled `destructive-text` when on, shown whenever `onToggleFavorite` is set. This replaces the white heart on a 45% black disc. |
| PhotoStrip | changed | New `format` prop (default portrait) applied to every tile. The empty add tile is `spacing-24` when the strip is landscape. The track is the shared scroller. |
| RecipeCard | changed (minor) | The heart follows PhotoCard (outlined until favourited). Wording only otherwise. |
| RecipeLinkCard | changed | **The thumbnail is PhotoCard `xs` `portrait`, 60×80** (previously an 80×80 square). New `format` prop. |
| DetailHeader | **changed** | **`facts` is now `string[]`**, drawn as a `sans-sm text-tertiary` " · " line. **New `badges: BadgeProps[]`** for statuses only (Staple, Pro, Archived). Recipe: facts are time and method, the badge is the rotation goal. |
| Input | **changed** | **One style:** `soft`. `outline` is removed; `plain` is only for use inside a list row. The border is **1px `line`** (previously 0.5px `line` at 30%). Hover: 1px `line-control`. **Focus: 2px `primary` at 100%. Error: 2px `destructive` at 100%** (both previously 1.5px at 80%). **Read-only** (new): no border, `text-secondary`. Disabled keeps its border and shows `text-tertiary` contents (no 50% fade). New props: `hint`, and `error` as a string message (shown with an alert glyph and replacing the hint). Only the border animates. |
| TextArea | changed | Same states as Input. Adds `maxLength` with a live `{n} / {max}` counter. Going over the limit is an error state, not a hard stop. Adds `hint`, `readOnly` and an error message. |
| TasteScoreSelector | unchanged | none |
| RatingList | **changed** | Rows are now ListRows. There is a **second shape:** `rows[{label, note, value}]` + `bar`, which is a generic "header + meter + rows" block (SegmentedBar's `legend="rows"` uses it). A row with a zero value is never dimmed; only its figure turns tertiary. **No avatar or action in the rater shape** (`raters[{name, role, score, vsUsual}]`). |
| Timeline | changed (minor) | The track scrolls with snapping (previously clipped). |
| BottomSheet | unchanged | Uses Bar instead of ProgressBar. |
| ListRow | **new** | `leading` (Avatar, PhotoCard `xs`, rank `Text serif-xs`, Icon), `title`, `meta`, `value` (tabular, key–value), `trailing` (one element, or two when the second is a ghost icon button), `chevron` (default when pressable), **`unread`** (primary dot in the gutter plus a semibold title), `tone: destructive`, `size` sm 44 or md 56. Five shapes: Navigation, Key–value, Toggle, Subject, Invite. |
| Toggle | **new** | Track 48×28 (`s12`×`s7`) `radius-full`: `track` when off, `primary` when on. Knob 24 (`s6`), `stone-0`, `shadow-xs`. Has a 44pt hit area and one size. Only used in a ListRow's trailing slot, with no "On/Off" text. |
| EmptyState | **new** | `layout`: **screen** (`serif-md` centred, `primary solid md`), **card** (`serif-sm` in a Card, `primary soft sm`), **plain** (`serif-sm`, left-aligned), **row** (`sans-sm tertiary`, no message, action pushed right). Also `title`, `message`, an optional `icon` (`text-tertiary`), `action` and `secondaryAction`. No artwork. |
| SegmentedBar | **new** | Built on Bar. `legend`: `true` (swatch + label, inline) or `'rows'` (a RatingList). `format`: count or percent. `size`: sm 6, md 10, lg 16 (**different from Bar's sizes**). `title`/`trailing` wrap it in a Section. Legend keys are a **rounded-square swatch**, not a dot or a Badge. Reaction segments always run in scale order. |
| ValueStepper | **new** | Two AppButtons `secondary soft iconOnly` (44) around a **`sans-lg` tabular readout, `s10` wide**. Props: `min`, `max`, `step`, `unit`, `formatValue`, `size` (sm, md), `label`. Showing the number without a unit is the default. Buttons are disabled at the limits, and there is no Apply. |
| PendingInviteRow | **removed** | Use ListRow's Invite shape: Avatar `sm` + email + "Invited {when}" + Resend (`secondary ghost sm`) + revoke ✕ (`destructive ghost sm iconOnly`). No "Pending" badge. |
| LabeledPhotoCard, RecipeShelf, PartyCard | new (stubs) | Generated cards with no props. They are listed under "Still to design", so treat them as not specified. |

---

## 4. Impact on our Swift code

Verdicts: **KEEP** = already matches v2. **ADJUST** = small, listed edits. **REWRITE** = the API or behaviour changes enough that the file is redone. **DELETE** = remove the file.

### Core/Design

| file | verdict | changes |
| --- | --- | --- |
| DS+Color.swift | ADJUST | Add `lineControl = C(light: "#7a8089", dark: "#7a8290")`. `destructive` becomes `#d93229` / `#d93b31`. `onPrimary` becomes `C(light: "#ffffff", dark: H.pine900)`. Make `onDestructive` an explicit light/dark pair (cosmetic). Update the `lineStrong` doc to say decorative only. Delete `photoDisc` once PhotoCard's heart moves to AppButton (it is only used there). |
| DS+Palette.swift | KEEP | `pine900` is already in `Hex`. |
| DS+Spacing.swift | KEEP | Values unchanged. PhotoCard portrait needs 60 and 216, which have no token: compute them as `long × 0.75` inside PhotoCardSize rather than adding steps. |
| DS+Radius / DS+Shadow / DS+Opacity | KEEP | Unchanged. `Opacity.focus` and `Opacity.hairline` lose their Input use but stay as tokens. |
| DS+Typography.swift | ADJUST | Change `defaultWeight` (line 54) to always return `.regular`. Then make every `.sansLg` caller that relies on it pass `weight: .semibold`: AppButton lg labels, sheet and reason titles, change badges. |
| DS+ColorDeprecated.swift | KEEP | none |
| DesignTokens.swift | ADJUST | Update the source-of-truth URL if v2 lives at a new artifact. |
| DesignTokensPreview(+Data).swift | ADJUST | Add a `lineControl` swatch. Its destructive swatch picks up the new value automatically. |
| DS-GAPS.md | ADJUST | See the gap table below. Remove #1–5, #12 and #13. |

### Foundations

| file | verdict | changes |
| --- | --- | --- |
| DSAxes.swift | ADJUST | `outlineBorder` for `.secondary` becomes `DS.Color.lineControl` (currently `lineStrong`). |
| CameraPicker, HotReloadHost, NomNomPreview, PhotoTools | KEEP | none |

### Primitives

| file | verdict | changes |
| --- | --- | --- |
| AppButtonTypes.swift | ADJUST | Add `case xs` (height `s11`, padding `s2_5`, `.sansXs`, gap `s1`). Change `sm.height` from `s9` (36) to `s11` (44). Icon-only size is always `s11`, and every size gets a 44pt minimum width. Map the legacy `.sm`/`.md`/`.xl` the same way. Roughly 110 `size: .sm` call sites (buttons and badges mixed) will reflow, so check rows. |
| AppButton.swift / AppButtonLabel.swift | ADJUST | Icon-only frame becomes a fixed 44 for all sizes (`AppButtonLabel.swift:59`). Pass `.semibold` explicitly for lg once `sans-lg` is regular. |
| Badge.swift / BadgeHelpers.swift | KEEP | `.rank(_:)` stays for non-row uses. In rows, rank becomes `Text serif-xs` (ListRow already does this). |
| Avatar.swift | KEEP | none |
| ScoreValue.swift | KEEP | none |
| ProgressBar.swift | **REWRITE as `Bar.swift`** | Add `segments: [BarSegment]` (value, reaction or colour, label), 1px `panel` seams, `max` with segments, and `role=img` labelling. Keep `ProgressBar` as a deprecated wrapper. Drop the `featured` prop, which v2 doesn't have; a fill is `primary`. 9 call sites. |
| SectionHeader.swift | ADJUST | **Remove `inset`.** Move the `sectionInset` padding and `s2` bottom spacing into `DSSection`. The trailing figure: v2 doesn't say whether it is `sans-sm` or `sans-xs`; pick one. The title currently uses **`weight: .semibold`**. In v2 the title is `sans-xs` at regular weight, with semibold only for `variant: .primary`, so drop the default semibold. Truncate the title before the trailing figure (it already has `.layoutPriority(1)`). 11 `inset: false` call sites. |
| Input.swift / AppInputTypes.swift | **REWRITE (states)** | Remove `InputAppearance.outline`, and map `AppInputStyle.outlined` to `.soft` (19 `.outlined` plus 5 `.outline` call sites). `restingWidth` goes from 0.5 to **1**, and the colour from `line` at 30% to `line` at 100%. `activeWidth` goes from 1.5 to **2**, with full-strength `primary`/`destructive` (no `Opacity.focus`). Add `isReadOnly` (no border, `textSecondary`, no clear button). Disabled stops using 50% opacity; the border stays and contents turn tertiary. Add `hint: String?` and an error `String?` message row with an alert glyph. Animate only the border. |
| Input+Legacy.swift | ADJUST | Map `.outlined` to `.soft`. |
| TextArea.swift | ADJUST | Same state changes. Add `maxLength` and a counter; over the limit shows the error state. Add `hint`, `readOnly` and the error message. |

### Layout

| file | verdict | changes |
| --- | --- | --- |
| Card.swift | KEEP | The preview uses `ProgressBar(featured:)`; switch it to Bar. |
| DSSection.swift | ADJUST | Takes over the side inset and bottom spacing from SectionHeader. |
| SectionCard.swift | **REWRITE (small)** | Delete `SectionCardLayout`. The card always renders the label inside with `s1_5` before the content (the current `.inset` path). **Current call sites with the default `.stacked` (about 74) will move their label inside the card.** v2 prefers this; where a label must stay above, use `DSSection { Card {…} }`. Add an optional `action` (pressable). |
| SectionCard+Legacy.swift | ADJUST | Deprecated inits now get the inside-the-card label too (no code change, but layout changes). |
| PageHeader.swift + PageHeading.swift | **REWRITE → one `PageHeader`** | `title`, `subtitle`, `eyebrow`, `actions: [EmptyStateAction]` (first solid, rest ghost; lg at md, md at sm; at most 2), `align` (**default `.start`**; ours defaults to center), and `size` (sm `serif-md`, md `serif-lg`). Delete PageHeading after migrating its 7 call sites, whose single "Add meal" button becomes a `primary solid` action. |
| LabeledWrappingRow, WrappingHStack, SwipeActionRow, SwipeableListCard | KEEP | Still not in the DS. |

### Composites

| file | verdict | changes |
| --- | --- | --- |
| PhotoCard.swift / PhotoCardSource.swift | ADJUST | Split `PhotoCardSize` (long edge: xs 80, sm/md 192, lg 288) from a new `PhotoCardFormat` (square, portrait, landscape; 3:4). Defaults: xs square, sm portrait, md square, lg portrait. **lg portrait becomes 216×288 (currently 256×288).** Replace `favoriteHeart` with `AppButton(variant: .secondary, appearance: .elevated, iconOnly)` using `heart`/`heart.fill`, `destructiveText` when on, and an `onToggleFavorite` closure. `.thumb` and `.cover` remain gaps that v2 did not adopt. |
| PhotoStrip.swift | ADJUST | Add `format` (default portrait) and pass it to every tile. The empty tile is `s24` tall for landscape. |
| PhotoStripAddButton / PhotoStripEditor* | KEEP | `secondary elevated sm` is now 44 tall; check the overlay fits on sm tiles. Edit mode is still "to design". |
| RecipeLinkCard.swift | ADJUST | Thumbnail becomes PhotoCard `.xs` with `format: .portrait` (60×80). Add a `format` parameter. |
| RecipeCard.swift | ADJUST | The heart comes from the new PhotoCard API (outlined or filled plus a toggle closure). |
| DetailHeader.swift | ADJUST | `facts: [Badge]` becomes `facts: [String]`, drawn as `Text(joined " · ").textStyle(.sansSm, tone: .tertiary)`. Add `badges: [Badge]` for statuses. Use the SectionHeader eyebrow without `inset:`. |
| RatingList.swift / RatingRow.swift | ADJUST | Build rows on ListRow. Add a generic `rows: [RatingListRow(label, note, value)]` + `bar: Bar` initialiser for SegmentedBar. Use `Bar(size: .xs)`. `showsAvatars` and `RatingListAction` (rate/ask) are **not in v2**: keep them only as a documented deviation (ListRow trailing does allow an AppButton `sm`), or drop avatars. |
| ScoreCard.swift | ADJUST | ProgressBar → Bar. Otherwise KEEP. |
| SheetCard / SheetHero | ADJUST | SheetHero: ProgressBar → Bar; sheet title passes semibold. |
| Timeline / TimelineItem | KEEP | Already a horizontal ScrollView; sm portrait is 144×192, which matches. |
| TasteScoreSelector | KEEP | lg is 48, unchanged. |
| ProGate, BurnerMeter, CookingTimeSelector, RotationGoalSelector, TactileOptionPicker, TactileTasteSelector, CreateDropdownMenu, AssetPhotosPickerSection, MealPhoto, RemoteMealPhoto, RecipeImageView, PhotoScrim | KEEP | Not synced. BurnerMeter uses `lineStrong` as an unfilled meter step, which is a meaningful mark; consider `track`. |

### Interim

| file | verdict | changes (our interim compared with v2) |
| --- | --- | --- |
| ListRow.swift + ListRowSlots.swift | **ADJUST → move to Composites** | v2 matches about 80%. Rename `emphasized` to `unread` and add the primary gutter dot. Add `tone: .destructive` and `size` (sm 44, md 56). `ListRowTrailing.value` becomes its own `value` slot. Allow only one trailing element, or two when the second is a ghost icon button (currently it is an unbounded array). v2 has a single `meta`; our second `detail` line is an extension, so keep it with a note or drop it. `metaColor` is not in v2. Leading `.photo` uses `.thumb` (48), where v2 says PhotoCard xs (80); this is a gap. Toggle slot: v2 Toggle is 48×28, while native `Toggle` is 51×31. Decide: keep the native control tinted `primary` (recommended for iOS) or add a custom `DSToggle`. |
| PendingInviteRow.swift | **DELETE** | Replace with `ListRow` Invite shape: `.avatar(Avatar(name: email, size: .sm))`, meta "Invited {relative}", Resend → **`secondary ghost sm`** (we use `primary soft sm`), revoke → **`destructive ghost` iconOnly xmark** (we use a trash icon). Drop the "Pending" status. The async resend/revoke + inline feedback logic (about 60 lines) can move to a small `InviteRowModel` or `ListRow+Invite` helper. 8 call sites. |
| EmptyState.swift | **REWRITE (API)** | `EmptyStateStyle.standalone/.inCard` becomes `layout: .screen/.card/.plain/.row`. Add `icon` and `secondaryAction`. `screen` uses `serif-md` centred with `primary solid md`; `card` draws its own Card; `plain` is left-aligned `serif-sm`; `row` is `sans-sm tertiary` with the action on the right. Our `.inCard` (`sans-md tertiary` line inside a SectionCard) is closest to `row` or `plain`. `EmptyStateAction` already matches v2's action shape. 6 call sites, plus about 6 on the branches. |
| SegmentedBar.swift | **REWRITE** | Draw the track with `Bar(segments:)`: 1px `panel` seams instead of `s0_5` gaps. Use its own sizes (sm `s1_5`, md `s2_5`, lg `s4`) instead of `ProgressBarSize`. Legend becomes a rounded-square swatch + `sans-sm secondary` label (inline), or `legend: .rows` rendered as RatingList rows (swatch, `sans-md`, figure `serif-xs` tabular). Add `format` (count, percent) and `title`/`trailing` (wrapped in DSSection). Keep zero tiers at full strength and reaction tiers in scale order. Our `valueText`/`detail` are extras. |
| ValueStepper.swift | ADJUST | Buttons become `secondary soft` icon-only at 44 (`sm` icon-only is 44 once AppButton changes). Readout goes from `serif-sm` to **`sans-lg` tabular, `s10` wide**. Add `unit` and `formatValue`. Remove the built-in title and caption: v2 puts the stepper in the trailing slot of a labelled ListRow. Keep `optionalValue` as an extension. |
| LabeledPhotoCard, RecipeShelf, PartySummaryCard | KEEP (interim) | v2 has only empty stubs and lists them as "still to design". |
| TrendChart (+Tooltip, Series), MediaViewer* | KEEP (interim) | Still to design. |
| NameFieldsCard, PartyFormFields, VisibilityToggleCard, AccountActionsSection, View+AccountConfirmations | ADJUST (light) | Still to design, but they must pick up the Input single-style change. VisibilityToggleCard should become a ListRow + Toggle inside `Card(layout: .list)`. |

### DS-GAPS.md: what v2 now covers

| # | gap | covered by v2? | how our interim differs |
| --- | --- | --- | --- |
| 1 | ListRow | **Yes**: ListRow | `emphasized` vs `unread` + dot. No `tone` or `size`. Unbounded trailing array. Extra `detail` line. `.thumb` leading. |
| 2 | PendingInviteRow | **Yes, removed**: ListRow Invite shape | Different button styles (primary soft + trash vs secondary ghost + xmark). Shows "Pending". |
| 3 | EmptyState | **Yes**: EmptyState | 2 styles vs 4 layouts. No icon or second action. Different type steps. |
| 4 | SegmentedBar | **Yes**: SegmentedBar + Bar | Gaps vs seams. Dots vs swatches. No rows legend, format or title. Different sizes. |
| 5 | ValueStepper | **Yes**: ValueStepper | `serif-sm` vs `sans-lg` readout. Built-in title and caption. 36pt buttons. |
| 12 | Notification unread state | **Yes**: ListRow `unread` | A tinted ground is now explicitly forbidden; use a dot + semibold. |
| 13 | PageHeader | **Yes**: PageHeader | Two components vs one. Center vs start default. No eyebrow or actions array. |
| new | Toggle | **Yes**: Toggle | We use native `Toggle`. Decide whether to keep it. |
| 6–11, 14, 15 | TrendChart, MediaViewer, PhotoStrip edit, LabeledPhotoCard, RecipeShelf, PartyCard, form blocks, step toolbars | No (listed as "still to design") | Keep the interim versions. |
| stretch | PhotoCard `.thumb` (48) | No, v2 says ListRow leading is PhotoCard `xs` | Ask the DS owner: an 80pt thumbnail makes a 56pt row about 100pt tall. |
| stretch | PhotoCard `.cover` 4:5 | No, v2 formats are 3:4 | `portrait` 3:4 could replace 4:5, but the imagery rule still says 4:5 is safe. |

---

## 5. Impact on the three unmerged Phase 4 branches

None of the three branches changes a file that another branch also changes, so they merge independently. Total: 66 files, +2191 / −4258 lines.

### `worktree-agent-a51bdb629ee8a8c6c`: Meal Detail (22 files)

| choice on branch | v2 verdict | fix |
| --- | --- | --- |
| `MealDetailHeader.facts`: effort, kind and method as `Badge(.secondary, .sm)` | **Conflicts** (facts are not badges) | Pass `[String]` facts. These have no status badges (rotation is recipe-only). |
| `RatingList(entries:, showsAvatars: true)` | **Conflicts** (v2 rater rows have no avatar) | Drop `showsAvatars`, or record it as a deviation. |
| `SectionCard(note.title, layout: .inset, uppercase: false, quote:)` | Compatible in intent | Remove the `layout:` argument once SectionCard has a single shape. |
| `SectionCard("Historical scores")` / `SectionCard("Who thought what")` (default stacked) | Label moves inside the card | No action needed; the result is what v2 intends. |
| `MealRatingDistributionCard`: `SectionCard { SegmentedBar(segments) }` | Partly conflicts | Use `SegmentedBar(title: "Who thought what", trailing:, legend: true)`. This removes the SectionCard wrapper, because SegmentedBar owns the Section. |
| `ListRow` for people, member scores and history rows | Compatible | Gets the ListRow changes for free. Check no row has more than 2 trailing slots. |
| `EmptyState("Meal is gone", message:)` | API change | Use `layout: .screen`. |
| PhotoStrip and Timeline usage | Compatible | PhotoStrip tiles shrink to 216 wide (portrait default). |
| New `FoodStore+MealHistory`, `+MealRaters`, `UINavigationController+SwipeBack` | Not affected | Keep. |

### `worktree-agent-a2ac111ffe83074c4`: Recipe Detail and Party Detail (23 files)

| choice on branch | v2 verdict | fix |
| --- | --- | --- |
| `RecipeDetailHeader.facts`: effort (with a clock icon) and method badges, plus `.rotation(rotation)` | **Conflicts** | facts = `["30–60 min", "Baking"]` and badges = `[.rotation(rotation)]`. This is v2's own Recipe example. |
| `RecipeDetailInfoCard`: `ListRow("Dish kind", trailing: .badge(Badge(kind.name…)))` | **Conflicts** (a dish kind is a fact) | Use `.value(kind.name)`. |
| `ListRow("Servings", trailing: .value(...))` | Compatible | If servings stays editable here, use ValueStepper in the trailing slot. |
| `SectionCard(…, layout: .inset)` ×4 (health sheets, PartyJoinBanner `featured`) | Compatible | Remove the `layout:` argument. |
| `HealthMacroDistributionCard`: `SectionCard { SegmentedBar }` | Partly conflicts | `SegmentedBar(title: "Macronutrients", legend: true, format: .percent)` using `chart-series` colours. |
| `PartyMealsSection`: `EmptyState(alignment: .leading, style: .inCard)` inside SectionCard | API change | `EmptyState(layout: .plain)` inside the card, or `.card` without the wrapper. |
| `PartyDetailView`: `EmptyState(...)` | API change | `layout: .screen`. |
| `RecipePhotosCard`: PhotoCard tiles with a "Page N" Badge | Compatible | "Page N" is a label over a photo (elevated sm); it fits. |
| Favourite: custom `Image(systemName: heart)` toolbar button tinted `primary` | Minor conflict | v2 heart: outlined, then filled **`destructive-text`**. Use AppButton elevated iconOnly. |
| Party DetailHeader: meta "members · followers · Private", centred, Avatar | Compatible | "Private" could become a `badges` status (it can change). This is optional. |
| `RecipeScoreCards`: rank moved into the ScoreCard caption | Compatible | Matches "rank is not a badge". |
| `PartyMembersSection` ListRows | Compatible | Invite rows elsewhere still use PendingInviteRow. This branch has no invite rows. |

### `worktree-agent-aab9de4e9eb90a201`: arc deck removal (21 files)

| choice on branch | v2 verdict | fix |
| --- | --- | --- |
| `SignInView`: `PageHeader(...)` (old, center-aligned) | API change | New PageHeader with `align: .center`, an `actions` array and `size`. |
| `MealsView`: `PageHeading(title: "Meals", actionTitle: "Add meal")` | API change | `PageHeader(title:, actions: [Add meal])`. PageHeading is deleted. |
| `MealsEmptyStateView`, `MyRecipesSection`, `RecipeLeaderboardSheet`, `MealEditorRecipeSection`: `EmptyState(...)` | API change | Choose `.screen` for the whole-screen first run and `.card` or `.plain` for blocks. `ProfileMealHistorySection` `.inCard` becomes `.plain`. |
| `RecipeLeaderboardRow`: `ListRow(leading: .rank(n))` | Compatible | Rank as `Text serif-xs` is exactly v2. |
| `MealRow` / `ProfileMealHistorySection`: `leading: .photo(.meal)` (48 thumb) | Gap | v2 says xs (80). Keep the thumb until the DS owner decides. |
| `FoodCalendarView`: `AppButton(..., size: .sm)` ghost chevrons and "Today" | Reflow | They become 44pt (were 36), so check the header height. Calendar is slated for deletion in Phase 6 anyway. |
| `MealRatingPhotoHeader`: `PhotoStrip` + `DetailHeader` | Compatible | none |
| `MealRatingSheet`: `SectionCard(title: "Notes & Review")` | Label moves inside the card | Fine. |
| `AppIconMark` (app icon + "Nom Nom" in Newsreader) | Compatible | Logo rules are unchanged. |

---

## 6. Recommendation

### How much is reusable

| layer | reusable as-is or with ADJUST | notes |
| --- | --- | --- |
| Tokens (Core/Design) | ~97% | 4 colour edits + one weight default |
| Primitives | ~80% | AppButton sizing, Input/TextArea state rework, ProgressBar → Bar |
| Layout | ~75% | SectionCard single shape; PageHeader merge |
| Composites | ~85% | PhotoCard format and heart; DetailHeader facts; RatingList on ListRow |
| Interim | ~60% | ListRow and ValueStepper adjust; EmptyState and SegmentedBar rewrite; PendingInviteRow deleted; chart, media and form blocks untouched |
| Phase 4 branches | ~85–90% | Screen structure, store helpers and arc removal all hold. About 20 call-site edits. |
| **Overall** | **~80–85%** | No phase needs to be thrown away. v2 is a refinement layered on top of what exists. |

### Suggested restart order

1. **Merge the three Phase 4 branches into `feat/design-system` first.** They change no file in common, and fixing about 20 call sites once is cheaper than rebasing three branches over breaking DS changes.
2. **PR "v2 tokens"** (small):
   - `lineControl`, `destructive`, `onPrimary` dark, `onDestructive`.
   - `sansLg` regular, plus explicit `.semibold` at its callers.
   - `DSAxes.outlineBorder` uses `lineControl`.
   - Token preview.
3. **PR "v2 primitives"**:
   - AppButton `xs`, `sm` = 44, 44pt floor for icon-only buttons.
   - `Bar` (ProgressBar becomes a deprecated wrapper).
   - SectionHeader without `inset` (spacing moves into DSSection), regular-weight title.
   - Input/TextArea: one style, 1pt/2pt borders, readOnly, hint, error message, maxLength.
   - Decide on Toggle.
4. **PR "v2 layout and composites"**:
   - SectionCard single shape.
   - PageHeader merge (delete PageHeading).
   - PhotoCard `format` + AppButton heart (delete `photoDisc`).
   - PhotoStrip `format`, RecipeLinkCard portrait.
   - DetailHeader `facts: [String]` + `badges`.
   - RatingList on ListRow + `rows`/`bar` shape.
   - Update every call site in the same PR, including the merged Phase 4 screens.
5. **PR "promote interim"**:
   - Move ListRow to Composites (`unread`, `tone`, `size`, `value`).
   - EmptyState with 4 layouts.
   - SegmentedBar on Bar with swatch and rows legends.
   - ValueStepper readout.
   - Delete PendingInviteRow in favour of the ListRow Invite shape + helper.
   - Update DS-GAPS.md (remove #1–5, #12, #13).
6. **Resume Phase 5** (feature migration) on the v2 APIs, then Phase 6.
7. **Ask the DS owner, in parallel:**
   - The inconsistencies table in §2.
   - The ListRow thumbnail size (48 vs 80).
   - Whether RatingList may keep avatars and rate/ask actions.
   - Native vs custom Toggle on iOS.
   - Off-scale 60 and 216 in PhotoCard.
   - 4:5 vs 3:4 crops.
