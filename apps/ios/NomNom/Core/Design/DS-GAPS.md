# Design system gaps (iOS)

Source of truth: https://claude.ai/artifact/4jeEJ91V5eRxpDn8NtqNgK, vendored at `design-system/` (version in `design-system/VERSION`).

This is the hand-off for design-system work. It has four parts:

- **A. Open gaps**: patterns the app needs that the DS does not define yet.
- **B. Spec contradictions**: places where the snapshot disagrees with itself, and the call taken for each.
- **C. Values with no token**: values the spec gives that have no token, and what iOS draws instead.
- **D. Resolved**: gaps that have closed, kept as history.

The rule when the spec disagrees with itself: the component README wins over older root-README prose and over `index.d.ts` / `api/`. `bundle.css` settles anything a README leaves out. A call that breaks this rule says why.

## A. Open gaps (need DS work)

### Interim components (`Core/Components/Interim/`, built only from DS primitives)

| Component | Covers | What the DS needs to decide |
| --- | --- | --- |
| **TrendChart** (+ `TrendChartTooltip`, `TrendSeries`) | Insights and party taste trends: total line `primary`, members dashed `chart-series` by stable index, `line` gridlines, a `primary` area when there are no members, drag to scrub, tooltip = Card `sm` + `shadow-lg`, cleared on release | Stroke widths and dash (today total `border-thick`, members dashed `border-hairline`); what an 8th member gets (the palette repeats); whether the tooltip stays after release |
| **MediaViewerSheet** (+ `MediaViewerPage`, `MediaViewerSource`) | The one full-screen photo viewer: paged, "Photo 2 of 5" title, `.mediaViewerStyle()` (`stone-1000` ground, bar at `opacity-90`) | A dark-chrome viewer spec, including the bar's opacity (no 85% step) |
| **PageMenu** (+ `PageMenuSheet`) | The "…" menu on every root and detail screen, from the "Nom Nom iOS" canvas PageMenu artboard: context actions, the Dinner party picker (Just me + parties, Manage parties), Inbox / My profile / Settings, Get Nom Nom Pro / Help & feedback. Drawn as a native `Menu` (AppButton README: context menus use system buttons); the artboard's custom popover only fixes the groups and order. The label carries ListRow's unread dot, offset `spacing-1` | A toolbar overflow-menu spec, and a toolbar unread mark |
| **ProSection**, **ProLinkCard** (+ `ProEyebrow`) | Pro blocks inside a screen or sheet as the canvas draws them: `pro-soft` card, `radius-3xl`, `shadow-lg`, `spacing-5` padding, a "PRO" `sans-xs` semibold `tracking-widest` `pro-text` eyebrow with sparkles, a `serif-sm` title. Locked: a teaser sentence, the content blurred and capped at `spacing-28` (the canvas draws 120, which has no token), "Unlock with Pro" `pro solid lg` full width. The link variant ends in a `pro-text` chevron. Both read `EntitlementStore.hasProAccess`, like ProGate. The canvas gives the card `shadow-lg`, which the Card README ("no border or shadow") rules out for cards | A Pro gate component, and whether a gated card floats |
| **PersonHeaderRow** | The person at the top of the rater and member sheets: Avatar `lg`, a `serif-sm` (member sheet `serif-md`) name, a `sans-sm` tertiary meta line, a `primary-text` chevron, `spacing-14` minimum height. ListRow's title is sans and lives in a Card | A bare person/profile row, or a serif title option on ListRow |
| **Form blocks**: `NameFieldsCard`, `PartyFormFields`, `VisibilityToggleCard`, `AccountActionsSection`, `View+AccountConfirmations` | Name fields, party form, visibility toggle card, sign-out / delete-account actions and their alerts. Diary-only: `RatingBlocks`, `RecipeBasicsForm` | Form-section patterns |

### Composites with an interim mode

- **PhotoStrip edit mode** (`Composites/PhotoStripEditor` + `Tile`, `Item`, `+Drafts`). It uses PhotoCard `sm` tiles. Remove is AppButton `secondary elevated` icon-only (the one 44pt size). The first tile carries a "Cover" Badge `elevated sm`; recipe pages are badged "Page N". "Camera" is an AppButton and "Library" a PhotosPicker with an AppButtonLabel. Reorder works through the context menu and accessibility actions (Make cover, Move left, Move right) rather than drag, which would fight the horizontal scroll. Recipe page photos cannot be reordered. `Composites/AssetPhotosPickerSection` is the shared wrapper: a DSSection ("Photos", trailing "Optional") over the editor, opening MediaViewerSheet on tap. **The DS should say** whether it wants drag-to-reorder.
- **Sheet step toolbars**: `.sheetNextToolbar` (first step: close + "Next") and `.stepCommitToolbar` (pushed step: checkmark or spinner, no interactive dismiss while saving). MealDetailsStepView still writes its own toolbar, because one trailing slot switches between "Next" for a new meal and the checkmark when editing. **The DS should document** multi-step sheets.

### Not synced (kept, tokens applied; the DS lists these as "not synced")

- **Selectors**: CookingTimeSelector, RotationGoalSelector and TactileTasteSelector, all on the shared `OptionCell`. TactileTasteSelector is in the household eater rows; there is no compact DS taste control for a list row. PendingRatingCard's six `spacing-12` steps need 328pt and scroll sideways on an iPhone SE.
- **Swipe rows**: SwipeActionRow and SwipeableListCard.
- **Pro**: ProGate (a `pro-soft` Card shape, bottom fade, `shadow-lg` blur standing in for a blur token), PaywallPackageCard and the feature checklist. The DS should define a gate.
- **Auth**: OTPCodeField (Input's ground and borders at `spacing-14`, a `border-thick` caret blinking over `duration-layout`) and AppleSignInButton (Apple's control at the `lg` height). The DS should define a code field.
- **Recipe content**: the checkable two-column ingredients table, numbered steps on a rail (`primary-soft` disc), and their editors. There is no numbered-step component.
- **EditorialTextView**: positive / negative fragments in `primary-text` / `warning-text` at `serif-xs`.
- **Menus and chrome**: the page menu replaced SettingsDropdownMenu and NotificationBellButton (see PageMenu above). A toolbar text action ("Mark all read") is `sans-sm` semibold `primary-text`, which no rule covers. RecipeFilterToolbarButton is a system toolbar icon whose filled glyph marks active filters; there is no toolbar-state rule.
- **Brand mark**: AppIconMark, the app-icon photo at Avatar `xl` with `radius-2xl` and a hairline on the welcome screen. The DS has no logo or app-icon component.
- **Pickers in rows**: RecipeFilterSheet rows end in a native `.menu` Picker. There is no select / picker row.
- **RecipeScannerOverlay**: a `scrim` plus a Card with `shadow-lg`, capped at `spacing-72`.
- **Plumbing**: CameraPicker, PhotoTools, WrappingHStack.

### Questions for the DS

- **Avatar and Dynamic Type.** The circle is fixed, so initials can clip at accessibility sizes. Should Avatar scale?
- **Thumbnail in a row.** ListRow's photo lead is PhotoCard `xs` (80pt), so photo rows are about 96pt tall in a `spacing-14` row. Confirm.
- **Category cover crop.** LabeledPhotoCard `lg landscape` is 4:3, but "Imagery" says only 1:1 and 4:5 crops are safe. Confirm.
- **"Current row" state.** The recipe leaderboard can no longer mark the recipe it was opened from.
- **Field success state.** EmailInviteCard's "Invitation sent" sits in the hint slot with no colour.
- **ListRow meta.** There is one meta line and one ink, so meal notes, notification dates and the "Invitation resent" feedback lose their emphasis. The canvas tones "Waiting on 2" `warning-text` after the party name, so ListRow takes a `metaAccent` run (`ListRowMetaAccent`, default `warning-text`) joined with " · ".
- **Value step.** The README gives no type step for a ListRow `value` or a SegmentedBar inline figure. Both are `sans-sm` tabular.
- **Onboarding progress.** The Bar has no width in the navigation bar; it takes `spacing-20`.
- **AppButton `reaction solid`.** Neither README says how it looks ("A solid fill never carries text"). Only `soft` is used; `solid` inks `reaction-text` on the fill, as bundle.css does.
- **Semibold serif.** Only Newsreader Regular is bundled, so `weight: .semibold` has no effect on serif steps.
- **TextArea over `maxLength`.** The README doesn't say whether the hint turns `destructive-text`. Today only the border and the counter change.
- **PhotoStrip add tile title ink.** The README gives "'Add photo' `sans-sm` semibold" and no ink. It is drawn in `text-primary`.
- **Timeline rail.** bundle.css draws the 2px rail at `top: spacing-2.5` (centre 11), one point below the dot's centre (10). iOS centres the rail on the dot.

## B. Spec contradictions and the call taken

| Topic | The disagreement | Call |
| --- | --- | --- |
| Hairline width | Avatar and PhotoCard READMEs: "0.5px `line` ring at 30%"; tokens.json `border-hairline`: "Never 0.5px" | `.dsHairline()` = `border-hairline` (1pt) |
| Focus / error borders | Root "Motion and states": 1.5px at `opacity-80`; Input README: 2px full strength | Input: `border-thick`, `primary` / `destructive` |
| Tracking | `api/tokens.md` lists six steps (incl. `tracking-wider` for badges); tokens.json has `tight` and `widest` | tokens.json. Badge has no tracking; `tracking-tight` is opt-in (`trackingTight`) |
| Dynamic Type sizes | The README table maps `sans-sm` to `.footnote` (13) and `sans-md` to `.body` (17); the scale says 14 / 16 | Sizes from tokens.json; only the `relativeTo:` style from the table |
| AppButton heights | `index.d.ts` / api: 36 / 44 / 48; README: xs, sm and md are all 44 | README: xs/sm/md 44, lg 48, 44pt floor |
| Icon-only size | bundle.css: `lg` icon-only is 48 wide; README: "all four sizes are the same 44 × 44 circle" | README. The icon-only API takes no size |
| Outline border | AppButton README: "1.5px `{role}` border (`line-strong` for secondary)"; root README: meaningful lines are `line-control` at ≥3:1; bundle.css: `border-hairline`, secondary `line-control` | Against README-wins: `border-hairline` + `line-control`, because 1.5px has no token and `line-strong` fails 3:1 |
| Elevated button ink | README: `text-primary`; bundle.css: `{role}-text` except secondary | README |
| SectionHeader trailing | README: `trailingVariant` `secondary` · `primary`; `index.d.ts`: `trailingTone` `tertiary` · `accent` | README values under the Swift label `trailingTone` |
| Field rest border | Input "One style" table: "1px `line`"; its "Shape" and state table, and bundle.css: `line-control` | 1pt `line-control` at rest, 1pt `line` when disabled |
| Error border colour | Input README: `destructive`; bundle.css: `destructive-text` | `destructive`; label, icon and message in `destructive-text` |
| TextArea states | TextArea "Rules": 1.5px at `opacity-80`, disabled `opacity-50`; its "States": "Identical to Input" | Input's states; no opacity on fields |
| Input read-only ground | `index.d.ts`: "panel ground, text-secondary"; Input README: "The ground never changes" | README: `sunken`, no border, `text-secondary` |
| Bar on a featured card | bundle.css tints the track inside a primary card; Bar README: "Ground is `track`" | Always `track` |
| TasteScoreSelector role | Its "Toggle buttons, not radios" section vs its "Rules" (`role="radio"`) | Buttons with the selected trait; tap again to clear |
| TasteScoreSelector step size | AppButton: icon-only is 44; TasteScoreSelector: "AppButton `size="lg"` (`spacing-12` circle)" | 48pt steps via `AppButtonLabel(iconOnlyDiameter: DS.Spacing.s12)` |
| DetailHeader facts | Its Rules: "Facts are Badges"; its "Facts are not badges" section | Facts are text joined " · "; badges hold statuses only |
| PhotoCard formats | PhotoCard: square and 3:4; root "Imagery": "1:1 and 4:5 are safe" | PhotoCard's formats; the 4:5 `.cover` is gone |
| Favourite heart ink | PhotoCard README: `destructive-text` when on; bundle.css: `primary-text` | README |
| SegmentedBar key | Its README: "Not a Badge"; `index.d.ts`, the root composition table and its zero rule: Badge | Swatch (`radius-sm`) |
| SegmentedBar `lg` | SegmentedBar: `lg` = `spacing-4`; Bar stops at `xl` (`spacing-3`) | `lg` maps to Bar `xl` (12) |
| LabeledPhotoCard `lg` radius | bundle.css: `radius-2xl` on every size; PhotoCard `lg`: `radius-3xl` | PhotoCard's radius, so the scrim matches the photo |
| ListRow title weight | `index.d.ts`: semibold when pressable or unread; README: unread only | Both |
| Notification unread | Plan: SectionCard featured; ListRow README: "a dot — never a tinted ground" | ListRow `unread` dot |
| Scroll bars | Root README / PhotoStrip: "absent on touch, where the platform draws its own. Never hide the scrollbar outright" | Horizontal scrollers (PhotoStrip, editor, RecipeShelf, Timeline, PartyCard) keep the system indicator |
| Verdict word vs numeral | Badge: "≥85 Amazing" on the 0–100 numeral; `Reaction(score:)` thresholded the raw 0–1 score, so 0.849 read "85 · Great" | `Reaction(score:)` thresholds the rounded numeral |

## C. Values with no token

| README text | iOS draws |
| --- | --- |
| BottomSheet: "`scrim` behind" | The system sheet dimming (SwiftUI exposes no colour) |
| BottomSheet grabber, no radius named | `radius-sm` (bundle.css), `spacing-2` from the top; the system indicator's VoiceOver resize action is lost |
| TasteScoreSelector: "a 1.5px fill ring" | `border-thick` (tokens.json: "selected ring") |
| TasteScoreSelector: "Spring 0.25 / 0.75" | The README values, quoted in code (no spring token) |
| Root "Motion and states": "Selection springs (≈0.25s)" | `.spring(duration: duration-layout)` |
| Toggle: "Pressing scales the knob", no duration | `duration-state` for slide and scale (bundle.css transition) |
| PhotoCard: "`portrait` and `landscape` are both 3:4" | `shortEdgeRatio = 3/4` (`ds-lint:allow`); xs portrait 60 and lg portrait 216 fall off the spacing scale |
| PhotoScrim / "Imagery": `stone-1000` at 72%, clear at 32% | The quoted values (`ds-lint:allow`) |
| PhotoStrip dashed border: no dash pattern | `spacing-1` on / `spacing-1` off |
| Photo overlays (white on photo) | `stone-0`, the ramp step under the `stone-1000` scrim |
| Input: "an alert glyph" | `exclamationmark.circle` at `sans-xs` |
| AppButton loading: spinner 1em with a `border-thick` ring | `ProgressView` `.mini` (xs, sm) / `.small` (md, lg) |
| ProGate blur | `shadow-lg`'s blur radius |
| Bar chart index past `chart-series7` | `primary` ("A block with no `reaction` or `color` is `primary`") |
| RatingList row value: no step | `serif-xs` tabular (SegmentedBar rows), `sans-sm` in the general shape |
| Hover, focus ring with offset | Pointer-only rules; not drawn on iOS |

## D. Resolved

- **v3 components shipped** (each follows `design-system/components/<Name>/README.md`): AppButton, AppButtonLabel, Badge, Avatar, Bar (replaced ProgressBar), ScoreValue, Text (`.textStyle`), SectionHeader, AppToggle, Input, TextArea, Card, DSSection, SectionCard (one layout; `stacked` / `inset` gone), PageHeader (replaced PageHeading), BottomSheet (`.dsSheet`, SheetBody, SheetCard, SheetHero), ListRow (replaced every hand-built row, including the PendingInviteRow copies, now `PartyInviteRow`), EmptyState (replaced every `ContentUnavailableView` and "No … yet" card), DetailHeader, ScoreCard (replaced DividedScoreCard), PhotoCard (owns the photo → cuisine → no-photo fallback), PhotoStrip (replaced the arc decks), RatingList, Timeline, RecipeCard, RecipeLinkCard, RecipeShelf, PartyCard, SegmentedBar, ValueStepper, LabeledPhotoCard and TasteScoreSelector.
- **DS sync 1790937820-8ae8** (2 Oct 2026, from the "Nom Nom iOS" canvas): buttons no longer scale on press (`AppPressableButtonStyle` is opacity only); the PhotoStrip floating Add photo button and its collapse became a trailing `PhotoStripAddTile` the size of a photo (which also settles the old `spacing-9` collapsed-circle and `line-placeholder` calls); Timeline gained `size: .mini`; PartyCard recent meals are a Timeline `mini` with dates; ListRow allows two labelled trailing buttons (Accept / Decline, Resend / Revoke) and never an unlabelled ✕.
- **Removed with no replacement**: the arc photo decks (PhotoStrip and PhotoCard replace them; empty states have no artwork unless the DS defines some) and the eater emoji (Avatar initials replace them).
- **Removed in Phase 6** (no callers, or shims): every `@available(*, deprecated)` alias and legacy initialiser (DS+ColorDeprecated, the pre-spec `DS.Spacing` names, `AppRadius`, the legacy AppButton / AppButtonLabel / Input / TextArea / SectionHeader / PageHeader initialisers, `AppButtonVariant` / `AppButtonStyle`, `AppInputStyle` / `Size` / `Shape`, `InputAppearance.outline`, `DSAppearance.outlineWidth`, `nativeToggle()`, `Font.newsreader(_: Font.TextStyle)`, `sheetCloseToolbar(color:)`, `SwipeableListCard.dividerPadding`). Dead code: CreateDropdownMenu, TactileOptionPicker, BurnerMeter, RecipeImageView, RemoteMealPhoto, MealPhoto, Font+Newsreader, Int+Ordinal, View+PendingState, `sheetDoneToolbar`, `photoBottomScrim`, PartyListView and the unused Dish-era typealiases. The dead Calendar feature, the Suggestions UI and the unreferenced Diary views went in the commit before.
- **Settled earlier and kept**: Card gap 0 by default; ScoreCard shows no rank; RatingList rows have no avatars; ListRow API (`meta`, `value`, one `trailing` slot, `trailingAction`, `chevron`, `unread`); EmptyState copy follows the README table; sheets use the BottomSheet metrics; the paywall Subscribe button is `pro solid lg`; macros put grams in the label; chart series go by stable member index; PartyCard `discover` uses Follow instead of "Ask to join", because the app follows public parties rather than asking to join.
