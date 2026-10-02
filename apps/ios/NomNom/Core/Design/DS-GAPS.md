# Design system gaps (iOS)

Source of truth: https://claude.ai/artifact/4jeEJ91V5eRxpDn8NtqNgK

This file lists UI patterns that exist in the app but not in the design system. Each one either has a single interim component in `Core/Components/Interim/` or is kept as-is with tokens applied. Remove an entry once the design system covers it and the interim component has been replaced.

## Interim components (consolidated, built from DS primitives, to be designed)

| # | Component | What it covers | Replaces |
| --- | --- | --- | --- |
| 1 | **ListRow** | Leading slot (Avatar, PhotoCard xs, rank numeral), title, meta, and a trailing slot (Badge, ScoreValue xs, AppButton sm, Toggle, chevron). Also handles toggle rows and key-value rows. Lives inside `Card(layout: .list)`. | MealRow, profile/recipe/meal history rows, leaderboard row, member rows, party rows, notification row, settings nav rows, info rows |
| 2 | **PendingInviteRow** | Email, "Pending", Resend, revoke | 4 invite-row copies (party invite, members sheet, party setup, household) |
| 3 | **EmptyState** | Title, message, optional AppButton; no artwork for now | ContentUnavailableView uses, "No … yet" cards, arc empty states |
| 4 | **SegmentedBar + legend** | Distribution of reaction tiers, macros, health tiers | 4 hand-built segmented bars |
| 5 | **ValueStepper** | Minus / value / plus | Recipe servings |
| 6 | **TrendChart** (+ tooltip card) | Single or multi-series line/area chart with scrub | InsightsTrendChart, PartyTasteTrendChart, PartyTrendTooltipCard |
| 7 | **MediaViewerSheet** | Full-screen paged photo viewer, dark chrome | 3 viewer sheets |
| 8 | **PhotoStrip edit mode** | Reorder, remove, "Cover" badge, add | Photo pickers in the meal, recipe, scanner and party-cover editors |
| 9 | **LabeledPhotoCard** | Category tile or cover with a scrim label and a selected state | CategoryGridCard, CategoryHeroCoverCard, cuisine picker tiles |
| 10 | **RecipeShelf** | Horizontal recipe carousel under a section header | 4 shelf variants |
| 11 | **PartyCard** | Party summary with score and recent meals; "mine" and "discover" modes | PartyCard, CurrentPartyHeroView |
| 12 | **Notification unread state** | Highlights an unread row | Tinted notification card |
| 13 | **PageHeader** | Hero title and subtitle on screens without a subject (sign-in, onboarding, paywall) | PageHeader, PageHeading |
| 14 | **Form blocks** | Name fields, party form, visibility toggle card, account/danger actions | Duplicated form cards |
| 15 | **Sheet step toolbars** | "Next" and step-commit toolbars for multi-step sheets (native; the convention needs documenting) | 8 hand-written toolbars |

### Interim files and token stretches

- `Interim/ListRow.swift` + `ListRowSlots.swift` (#1), `PendingInviteRow.swift` (#2), `EmptyState.swift` (#3), `SegmentedBar.swift` (#4), `ValueStepper.swift` (#5), `LabeledPhotoCard.swift` (#9), `RecipeShelf.swift` (#10), `PartySummaryCard.swift` (#11; renamed `PartyCard` once the feature PartyCard is replaced in Phase 5).
- **PhotoCard `.thumb`**: `s12` square, `radius-xl`, no badge, for ListRow leading thumbnails. The DS's smallest tile (`xs`, `s20`) is taller than a `rowMin` row.
- **PhotoCard `.cover`**: 4:5 (`s16` × `s20` ratio, used with `fillsWidth`), `radius-3xl`, for LabeledPhotoCard `.portrait`. The DS has no 4:5 tile; 4:5 is one of the two safe crops of the square category photography.
- **Category hero cover**: today a wide 140pt banner. A wide crop is not safe (README: only 1:1 and 4:5), so it becomes a full-width LabeledPhotoCard `.square`. That is tall for a header; the DS should decide whether drill-downs get a cover at all.
- **PartySummaryCard score**: ScoreCard `compact` is itself a Card and Cards don't nest, so the party card draws ScoreCard compact's content (ScoreValue `sm`, count, Bar) without the surface.
- **PendingInviteRow feedback**: "Invitation resent" and errors show in the row's meta line instead of alerts.
### Notes: charts, media and form blocks (rows 6, 7, 8, 14, 15)

- **6 TrendChart**: `Interim/TrendChart` + `TrendChartTooltip` + `TrendSeries`. Values are 0–1 and read ×100. The total line is `primary`, member lines are dashed `chart-series` by stable index, gridlines are `line`. With no member series it draws a `primary` area under the total. Drag to scrub (native `chartXSelection`); the tooltip is a `sm` Card with `shadow-lg` and clears on release. `visibleDays` makes the x axis scroll. For the DS to decide: stroke widths and dash (today 3pt total, 1.5pt dashed members), what an 8th member gets (the palette repeats), and whether the tooltip should stay after release.
- **7 MediaViewerSheet**: `Interim/MediaViewerSheet` + `MediaViewerPage` + `MediaViewerSource` (stored paths, a PhotosDraft or a RecipeDraft). Paged TabView, "Photo 2 of 5" title, `.mediaViewerStyle()`.
- **8 PhotoStrip edit mode**: `Composites/PhotoStripEditor` (+ `Tile`, `Item`, `+Drafts`). PhotoCard `sm` tiles. Remove is an AppButton `secondary elevated sm` xmark. The first photo gets a "Cover" Badge `elevated sm`, or every photo gets "Page N" for recipe pages. "Camera" (AppButton) and "Library" (PhotosPicker with an AppButtonLabel) add photos; empty, it shows PhotoStrip's dashed add tile. Reordering uses each tile's context menu and accessibility actions (Make cover, Move left, Move right) rather than drag, because a drag fights the horizontal scroll. Recipe page photos can't be reordered: RecipeDraft keeps stored and new pages in separate lists. The DS should say whether it wants drag-to-reorder. PartyDetailHeader's cover picker moves in Phase 4.
- **14 Form blocks**: `Interim/NameFieldsCard`, `PartyFormFields`, `VisibilityToggleCard`, `AccountActionsSection` and `View+AccountConfirmations` (the one copy of the sign-out and delete-account alerts). Two feature-level blocks are used only by Diary: `Features/Diary/Components/RatingBlocks` (taste and rotation) and `RecipeBasicsForm` (cover, name, cooking time, cuisine).
- **15 Step toolbars**: `.sheetNextToolbar` (CreateRecipeSheet, RecipeEditSheet, CreatePartySheet) and `.stepCommitToolbar` (MealVerdictStepView, RecipeDetailsStepView, PartySetupStepView). MealDetailsStepView still writes its own toolbar, because one trailing slot switches between "Next" (new meal) and the checkmark (editing).

## Kept as-is, tokens applied only (the DS lists these as "not synced")

- Selectors: BurnerMeter, CookingTimeSelector, RotationGoalSelector, TactileOptionPicker, TactileTasteSelector (household eater rows)
- Swipe rows: SwipeActionRow, SwipeableListCard
- Pro: ProGate, paywall package cards, feature checklist
- Auth: OTPCodeField, AppleSignInButton
- Recipe content: ingredients table (checkable, two columns), numbered steps on a rail, and their editors
- EditorialTextView: sentence segments with positive/negative tones; those tones are not in the DS
- Menus: CreateDropdownMenu, SettingsDropdownMenu, NotificationBellButton (unread dot)
- Photo plumbing: CameraPicker, PhotoTools, RemoteMealPhoto, RecipeImageView, WrappingHStack, LabeledWrappingRow
- RecipeScannerOverlay (floating progress panel)

## Removed with no replacement

- Arc photo decks (ArcHeroHeaderView, HeroPhotoDeck*, MiniPhotoArcDeck, CategoryPhotoArcView, EmptyPhotoDeckHeroView, MealPhotoDeckArcView, AuthHeroArcView). PhotoStrip and PhotoCard replace them. If empty states should have artwork, the DS needs to define it.
- Emoji avatars for eaters. Avatar initials replace them.

## v3 spec calls made in R0 (tokens generated from `design-system/tokens.json`)

Where the vendored v3 snapshot contradicts itself, these are the calls taken. Revisit when the DS is updated.

- **`line-placeholder`** is named by `components/PhotoStrip/README.md` ("1.5px dashed `line-placeholder`") but does not exist in `tokens.json`. The main README says "the dashed placeholder tile … use `line-control`", so the Add photo tile uses `lineControl`.
- **Hairline width.** Avatar and PhotoCard READMEs say "0.5px `line` ring at 30%"; `tokens.json` `border-hairline` says "Never 0.5px". `.dsHairline()` draws `border-hairline` (1pt).
- **Focus / error borders.** README "Motion and states" says 1.5px at `opacity-80`; `components/Input/README.md` says 2px full-strength. Component README wins: the `DS.Opacity.focus` alias is gone and fields use `primary` / `destructive` at full strength.
- **Tracking.** `api/tokens.md` lists six tracking steps (incl. `tracking-wider` 0.05em for badges); `tokens.json` has only `tracking-tight` and `tracking-widest`. `api/tokens.md` is stale against `tokens.json` (it also still says `bg` #f2f3f5); `tokens.json` wins, so Badge has no tracking. Type styles carry no tracking either, so `tracking-tight` is no longer applied automatically to serif-lg/xl (opt in with `trackingTight`).
- **Dynamic Type.** The README table maps `sans-sm` → `.footnote` (13pt default) and `sans-md` → `.body` (17pt), while the scale says 14 / 16. Sizes come from `tokens.json`; only the text style each scales relative to comes from the table.
- **Photo overlays.** No token or README defines white-on-photo or the 45% black disc. PhotoCard's heart now uses the v3 heart (AppButton `secondary elevated`: `panel` ground, `destructive-text` filled heart); LabeledPhotoCard text and the media viewer spinner use `stone-0`, the ramp step under README "Imagery"'s `stone-1000` scrim.
- **Featured ProgressBar track** (`primary` at 18%) is not in v3: Bar README says "Ground is `track`".

## v3 spec calls made in R1a (AppButton, Badge, Avatar, Toggle, Text, SectionHeader)

- **AppButton heights.** `index.d.ts` / `api/components/AppButton.md` say "Heights spacing-9 / 11 / 12 (36 / 44 / 48)"; the AppButton README says xs, sm and md are all `spacing-11` and "No button is smaller than 44 × 44". README wins: xs/sm/md 44, lg 48, 44pt minimum width and height on every button.
- **Icon-only size.** bundle.css draws an `lg` icon-only button 48 wide (`spacing-12`); the README says "Icon-only, all four sizes are the same 44 × 44 circle." README wins: the icon-only API takes no size. A deprecated sized icon-only initialiser keeps `lg` at 48 for TasteScoreSelector until R2 (bundle.css also sets its steps to `spacing-12`).
- **Outline border.** AppButton README: "`outline` = clear + `{role}-text` + 1.5px `{role}` border (`line-strong` for secondary)". The root README ("A line that carries meaning is `line-control` … Outline buttons … hold at least 3:1") and bundle.css (`--bw: var(--border-hairline)`, secondary `--role-border: var(--line-control)`) disagree, and 1.5px has no token ("the only two widths the system draws" are 1 and 2). Called for `border-hairline` + `line-control`, against the usual README-wins rule, because the README value has no token and fails 3:1; DS-V2-DELTA.md made the same colour call. The old 1.5pt `DSAppearance.outlineWidth` is deprecated and still read by TasteScoreSelector, PhotoStripAddButton, AppInputTypes and TrendChart.
- **Elevated button ink.** AppButton README: "`elevated` = `panel` + `shadow-xs` + `text-primary`"; bundle.css uses `{role}-text` except for secondary. README wins: every elevated button inks in `text-primary`.
- **Focus ring and hover.** "focus 2px `focus-ring`, 2px offset" and hover are web/pointer rules; iOS draws its own focus for Full Keyboard Access and has no hover on touch. Not drawn.
- **Loading.** README: "A pending button keeps focus … drops the handler rather than `disabled`". `isLoading` no longer disables the button; it swallows the tap. The spinner uses `ControlSize` `.mini` (xs, sm) / `.small` (md, lg); bundle.css sizes it 1em with a `border-thick` ring, which `ProgressView` cannot draw.
- **Badge `title`** (tooltip) is `tooltip:` in Swift (`.help` + accessibility hint), because `title` reads as the label. `Badge.rank` is kept: the Badge README recipes list Rank, though ListRow draws a rank as `Text serif-xs`.
- **Avatar ring.** README: "0.5px `line` ring at 30% on both." Drawn with `.dsHairline` (1pt, see "Hairline width" above). Its `minimumScaleFactor(0.5)` was invented and is gone; at accessibility sizes the initials can now clip inside the fixed circle. The DS should say whether Avatar scales with Dynamic Type.
- **Toggle name.** `Toggle` collides with `SwiftUI.Toggle`, so it is `AppToggle` (README: "Names carry a prefix only where they collide with SwiftUI"). It is a `ToggleStyle` (`DSToggleStyle`) on `SwiftUI.Toggle` rather than an AppButton, so VoiceOver keeps switch semantics. `nativeToggle()` now draws the DS switch with its label beside it and is deprecated: the README says "No label beside the switch", so those Features call sites move into ListRow in R3/Phase 5.
- **SectionHeader trailing.** README / `api` card: `trailingVariant` `secondary` · `primary`; `index.d.ts`: `trailingTone` `tertiary` · `accent`. README wins on the values (`SectionHeaderTrailingTone.secondary` / `.primary`); the Swift label stays `trailingTone`. The README does not name the figure's type step: it is `sans-xs`, the label's own step (previously `sans-sm` when inset).
- **SectionHeader title weight.** README: "a `sans-xs` title in `text-tertiary`"; only `variant: 'primary'` is semibold. The default semibold is dropped. The title icon is `text-sm` (bundle.css `.nn-section-header__title .nn-icon`).
- **SectionHeader inset.** v3 removes `inset`; the v3 initialiser is `SectionHeader(title:)`. The unlabelled `SectionHeader(_:…, inset:)` is deprecated and still draws the old `spacing-2` inset by default, so Composites, Card, SectionCard and DSSection (not in R1a) keep their layout until R2 moves the inset into DSSection.
- **Navigation bar titles.** No README names a style for UIKit navigation titles. Inline titles use `sans-lg` semibold (README: "sans-lg … sheet and reason titles … (each sets semibold itself)"); large titles use `serif-lg` ("page and hero titles").
- **`Font.newsreader`.** The free-size `newsreader(size:)` (default 32) and its per-text-style size table are gone. `newsreader(_: DS.TextStyle)` replaces them; the deprecated `newsreader(_: Font.TextStyle)` maps through the README Dynamic Type table, with anything below `.title3` set as `serif-xs` ("Nothing is set in serif below text-xl"). EditorialTextView's 22pt highlights became `serif-sm` (24pt, the step relative to `.title2`).
## v3 spec calls made in R1b (Bar, ScoreValue, Input, TextArea)

- **ProgressBar removed.** Every call site now uses `Bar`; `Primitives/ProgressBar.swift` is deleted (no shim). SegmentedBar draws its track with `Bar(segments:)` and takes `BarSize`.
- **Bar on a featured card.** `bundle.css` tints the track inside a primary card (`.nn-card[data-variant="primary"] .nn-bar { background: color-mix(in srgb, var(--primary) 20%, var(--panel)) }`), but `components/Bar/README.md` says "Ground is `track`" and no token holds the mix. Bar always draws `track`.
- **Bar chart index out of range.** The README says chart colours go "by a stable index, never cycled" but not what happens past `chart-series7`. `BarSegment.Ink.chart(n)` past the palette falls back to `primary` (README: "A block with no `reaction` or `color` is `primary`").
- **Field rest border: `line` vs `line-control`.** Input README "One style" table says "1px `line`"; its "Shape" section says "`line-control`, never a half-pixel and never `line`" (WCAG 1.4.11), its state table says rest "1px `line-control`", and `bundle.css` `.nn-field` uses `--line-control`. TextArea README says "rest 1px `line`, hover 1px `line-control`" but shares Input's CSS. Call: rest is 1pt `line-control` for both; disabled is 1pt `line`.
- **Error border colour.** Input README: "2px `destructive`"; `bundle.css` uses `--destructive-text` for the error ring. Component README wins: `destructive`. Label, icon and message ink are `destructive-text` (both agree).
- **TextArea focus / disabled.** TextArea README "Rules" still says "1.5px `primary` / `destructive` at `opacity-80`" and "Disabled: `opacity-50`", contradicting its own "States" ("Identical to Input") and Input's README. Call: Input's states; no opacity on fields.
- **Hover.** Input README's hover state (1px `text-tertiary`) is "pointer only"; not drawn on iOS.
- **Alert glyph.** Input README: "the message prints below with an alert glyph"; no symbol is named. iOS uses `exclamationmark.circle` at `sans-xs` (`bundle.css` `.nn-field__msg .nn-icon { font-size: var(--text-xs) }`).
- **`InputAppearance.outline` / `AppInputStyle.outlined`** both draw `soft` (README: "`.outlined` … dropped"); `.outline` is a deprecated alias.

## v3 spec calls made in R2a (Card, Section, SectionCard, ScoreCard, BottomSheet, TasteScoreSelector, RatingList)

- **Card gap.** bundle.css `.nn-card { --nn-gap: 0 }`; the README says "a component sets the gap". `Card(spacing:)` now defaults to 0 (was an invented `spacing-3`); ScoreCard sets `spacing-3.5` / `spacing-3`, SectionCard `spacing-1.5`, SheetCard 0. The chevron is `text-base` (`sans-md`) with no weight (bundle.css `.nn-card__chevron`). `featured: Bool` is now `variant: CardVariant?` (`.primary`) on Card, SectionCard and ScoreCard.
- **Card hover.** bundle.css `.nn-card[data-pressable]:hover { background: sunken }` is pointer only; not drawn on iOS.
- **SectionCard has one shape.** The `layout` axis (`stacked` / `inset`) is gone; every SectionCard puts its label inside the card, and the old stacked call sites now render that way (README: "Prefer the label inside"). A label above a card is `DSSection(_:) { Card { … } }`. Children of a SectionCard are `spacing-1.5` apart, so form cards that used to get `spacing-3` between children are tighter. `SectionCard+Legacy.swift` (caption / color / innerPadding inits) is deleted; its 6 callers were migrated.
- **SectionCard `onClick`** (index.d.ts) is `action:`; CuisinePickerSection uses it in place of a hand-built row with its own chevron.
- **ScoreCard rank.** ScoreCard README: "No rank or leaderboard position on the card". The recipe's "Ranked 3rd of your recipes" caption is removed; the leaderboard stays behind the card's action.
- **BottomSheet scrim.** README: "`scrim` behind". SwiftUI's sheet dims with the system scrim and exposes no colour for it; not drawn.
- **BottomSheet grabber.** README: "grabber `spacing-10` × `spacing-1.5` in `grabber`". `.dsSheet` hides the system drag indicator and draws `SheetGrabber` (`radius-sm` from bundle.css, `spacing-2` from the top: the sheet's top padding). The system indicator's VoiceOver resize action goes with it; the README calls the grabber decorative.
- **BottomSheet body.** README: "padding `spacing-2`/`spacing-5`/`spacing-10`, gap `spacing-6`". `SheetBody` holds those; the health rationale and methodology sheets moved off `spacing-7` / `spacing-4` / `spacing-12`, and their leading control is the Close (`sheetCloseToolbar`), not Cancel.
- **SheetCard provenance ink.** README: "provenance `sans-xs`" with no ink named. It stays `text-tertiary`. `ReasonProps.weight` (index.d.ts) is not described anywhere, so SheetReason has no weight.
- **TasteScoreSelector toggle vs radio.** Its README's "Toggle buttons, not radios" section says `role="group"` + `aria-pressed`; its "Rules" still say "Radio group: `role="radio"` + `aria-checked`" and the markup line says `role=radiogroup`. Called for the dedicated section: each step is a button with the `isSelected` trait, tap again to clear.
- **TasteScoreSelector ring.** README: "a 1.5px fill ring". No 1.5px width exists; `tokens.json` `border-thick` is "focus ring, error border, selected ring", so the ring is `border-thick` (2pt). `DSAppearance.outlineWidth` is no longer read by TasteScoreSelector.
- **TasteScoreSelector step size.** AppButton README: icon-only buttons are one 44pt circle. TasteScoreSelector README: "a standard AppButton `size="lg"` (`spacing-12` circle …)" and bundle.css `.nn-taste__row > .nn-button { width: spacing-12; padding: 0 }`. The steps are labelled buttons, so the TasteScoreSelector README applies: 48pt circles, drawn with `AppButtonLabel` (`iconOnlyDiameter: DS.Spacing.s12`). Verdict line is `spacing-2` below (bundle.css `.nn-taste` gap; was `spacing-3`).
- **TasteScoreSelector spring.** README: "Spring 0.25 / 0.75." No motion token is a spring; the README values are used, quoted in code.
- **RatingList avatars.** README rows have no leading slot ("Name Text `sans-md`, role `sans-sm` `tertiary`, both in the row's `title`"). `showsAvatars` and `RatingListEntry.photoPath` are removed; Meal Detail's list has no faces.
- **RatingList rows vs ListRow.** README: "Rows are ListRows". Interim `ListRow` takes a plain-string title, so it cannot carry name + role in two styles; `RatingRow` draws ListRow's v3 metrics itself (bundle.css `.nn-row`: `spacing-14` minimum, `spacing-3` vertical padding; `.nn-row__trail` gap `spacing-2`). Fold it into ListRow in R3.
- **RatingList Rate / Ask actions.** The README names "the viewer's own state" but not the unrated actions. The `sm` AppButtons (Rate, Ask to rate, Asked) stay in the trailing slot, which ListRowProps allows ("AppButton 'sm'").
- **RatingList general shape.** `RatingList(_:trailing:rows:meter:)` takes `RatingListRow`s and any meter (index.d.ts `rows` + `bar`). The README gives no type for the row value; it is `sans-sm` tabular, `text-tertiary` when zero ("only the figure drops to `text-tertiary`"). SegmentedBar (R3) can move onto it.
