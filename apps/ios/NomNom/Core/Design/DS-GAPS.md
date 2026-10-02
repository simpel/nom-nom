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
