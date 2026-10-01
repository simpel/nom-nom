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
