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
- **PartySummaryCard score**: ScoreCard `compact` is itself a Card and Cards don't nest, so the party card draws ScoreCard compact's content (ScoreValue `sm`, count, ProgressBar) without the surface.
- **PendingInviteRow feedback**: "Invitation resent" and errors show in the row's meta line instead of alerts.

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
