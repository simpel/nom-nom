# Nom Nom — Agent Guidelines & File/Folder Structure Rules

These instructions define how the Nom Nom codebase is structured and the rules to prevent files from growing bloated and unmaintainable.

---

## 0. Design System First (read before any UI work)

Nom Nom has its own design system. It is the spec for every pixel in the iOS app.

- **Source of truth**: the artifact at https://claude.ai/artifact/4jeEJ91V5eRxpDn8NtqNgK, vendored read-only at `design-system/` (version in `design-system/VERSION`).
- **What to read, in order**:
  1. `design-system/README.md`: voice, colour roles, scales, typography, imagery, composition rules.
  2. `design-system/components/<Name>/README.md` for every component you touch or compose. Read it before writing the Swift.
  3. `apps/ios/NomNom/Core/Design/README.md` (how tokens reach Swift) and `Core/Design/DS-GAPS.md` (known gaps and the calls already taken).
- **Precedence when the spec disagrees with itself**: component README > root README > `bundle.css` > `index.d.ts` / `api/`. Log every such call in `DS-GAPS.md` section B.
- **The Swift side**: each DS component has one Swift counterpart in `Core/Components/` with the same name (`ListRow` ↔ `ListRow.swift`, `BottomSheet` ↔ `SheetBody` / `SheetCard` / `SheetHero` / `.dsSheet()`, `Section` ↔ `DSSection`, `Toggle` ↔ `AppToggle`, `Text` ↔ `.textStyle(...)`). Use it; never build a second version.

### Building UI: the lookup

Before writing any view, card, row, sheet or control:

1. **Find the DS component.** `ls design-system/components/`. If one fits, use its Swift counterpart with the axes its README defines. Do not add props, variants or sizes the README doesn't name.
2. **Compose before inventing.** If no single component fits, build the view from DS components (Card + ListRow + Badge, …). A feature view built only from DS components and tokens needs no gap entry.
3. **No equivalent? Flag it.** If the UI needs a pattern the DS does not define (a new visual shape, control, state or layout rule):
   - Shared across features → `Core/Components/Interim/<Name>.swift`, first line `// DS-GAP: pending design system — see Core/Design/DS-GAPS.md`. One feature → that feature's `Components/`.
   - Build it only from DS primitives and tokens.
   - Add it to `DS-GAPS.md` section A with what it covers and **what the DS needs to decide**.
   - **Tell the user in your reply**: name the component, why no DS component fits, and the DS-GAPS entry you added. Never add an unflagged gap.
4. **A value the DS doesn't give** → `DS-GAPS.md` section C, plus `// ds-lint:allow <reason>` on the line.

### Checks (run after any UI change)

```bash
scripts/ds-lint.sh        # invented values (sizes, colours, radii, opacities…)
scripts/ds-coverage.sh    # components with no DS equivalent and no DS-GAPS entry
```

Both must be clean. `ds-coverage.sh` errors on any `Core/Components` file that maps to no `design-system/components/<Name>` and has no `DS-GAP` header or `DS-GAPS.md` entry (`Foundations/` and `*Gallery.swift` are exempt). It warns on any feature view that calls no DS component. Fix the cause or add the gap entry; do not just silence it.

### When the design system is updated

Follow `Core/Design/README.md` → "Updating the design system": re-vendor, bump `VERSION`, regenerate tokens, run both checks, re-read changed component READMEs against `Core/Components`, then move closed gaps in `DS-GAPS.md` from A to D.

---

## 1. Directory & Folder Architecture

This is a pnpm/Turborepo monorepo. Three apps under `apps/`, shared configs under `packages/`.
Every `NomNom/...` path elsewhere in this doc is shorthand for `apps/ios/NomNom/...`.

```
design-system/          # Vendored snapshot of the design system artifact (see VERSION). Never hand-edit.
│                         README.md (rules), tokens.json (every value), components/<Name>/README.md
├── components/         # One README per component + bundle.css / index.d.ts (reference implementation)
scripts/
├── ds-tokens-swift.py  # tokens.json -> apps/ios/NomNom/Core/Design/Generated/DSTokens.generated.swift
├── ds-lint.sh          # Fails on invented values in Core/ and Features/. Must be clean.
└── ds-coverage.sh      # Fails on Core components with no DS equivalent and no DS-GAPS entry. Must be clean.
apps/
├── ios/NomNom/         # SwiftUI app
│   ├── App/            # App lifecycle, root navigation (RootTabView, RootView, NomNomApp)
│   ├── Features/       # Vertical slices: Auth, Diary, Insights, Notifications, Parties,
│   │   │                 Recipes, Settings, Suggestions (Engine only)
│   │   ├── Components/ # Feature-specific subviews, cards, sheets, pickers
│   │   ├── Views/      # Screen-level views
│   │   └── Engine/     # Feature-specific non-UI logic where present (e.g. Suggestions/, Recipes/)
│   ├── Core/           # Shared, feature-agnostic code
│   │   ├── Components/ # Design system components, in layers (see §7):
│   │   │   ├── Foundations/ # Axes and paint (DSAxes), preview host, camera/photo plumbing
│   │   │   ├── Primitives/  # AppButton, AppButtonLabel, Badge, Avatar, Bar, ScoreValue,
│   │   │   │                  SectionHeader, AppToggle, Input, TextArea
│   │   │   ├── Layout/      # Card, DSSection, SectionCard, ScreenHeader, SwipeableListCard
│   │   │   ├── Composites/  # ListRow, EmptyState, Skeleton, Facts, ScoreCard, PhotoCard, PhotoStrip,
│   │   │   │                  RatingList, Timeline, RecipeCard, RecipeLinkCard, RecipeShelf,
│   │   │   │                  PartyCard, SegmentedBar, ValueStepper, LabeledPhotoCard,
│   │   │   │                  TasteScoreSelector, ProMark/ProCard/ProGate/ProView (Pro),
│   │   │   │                  SheetBody/SheetCard/SheetHero (BottomSheet)
│   │   │   └── Interim/     # Patterns the DS does not cover yet (TrendChart, MediaViewerSheet,
│   │   │                      form blocks). Each is listed in Core/Design/DS-GAPS.md
│   │   ├── Design/     # DS+*.swift token aliases, Generated/ (never hand-edit), README.md, DS-GAPS.md
│   │   ├── Extensions/ # Foundation & SwiftUI extensions, sheet/navigation modifiers
│   │   ├── Fonts/      # Bundled Newsreader cuts (registered via INFOPLIST_KEY_UIAppFonts)
│   │   └── Parsing/    # Parsers, formatters, text helpers
│   ├── Domain/         # Models and entities (Meal, Recipe, Party, Profile, Reaction, HealthIndex, etc.) — NO UI code
│   └── Services/       # Backend, networking, data store
│       ├── FoodStore/  # FoodStore split into domain extensions (FoodStore+Meals, +Recipes, +Parties, etc.)
│       ├── Supabase/   # Supabase client config + PhotoCache
│       └── Billing/    # RevenueCat / subscription config
├── web/                # Next.js app — marketing site, privacy/support pages, and /admin dashboard
└── supabase/           # Backend: migrations/, functions/ (Edge Functions), seed.sql, tests/
packages/
├── eslint-config/
└── typescript-config/
```

---

## 2. File Sizing & Anti-Bloat Rules

To keep the codebase maintainable and readable:

1. **Target File Size (< 200–250 lines)**:
   - Strive to keep all Swift files under **200 lines**.
   - Any file approaching or exceeding **250–300 lines** MUST be broken down.

2. **One Primary View/Type Per File**:
   - Do not bundle multiple substantial views, models, or sheets into one file.
   - Small private sub-renderers are acceptable only if trivial (< 20 lines). Anything larger must be extracted into a dedicated component file.

3. **Proactive Decomposition**:
   - **Do NOT** expand an existing large view by appending `@ViewBuilder private func ...` or embedding inline modal sheets.
   - When introducing a new visual section, modal sheet, header card, or complex interactive element, **create a new file in `Components/` immediately**.

4. **Sheet & Dialog Isolation**:
   - Every modal sheet, bottom sheet, or complex dialog must live in its own file under `Features/<Feature>/Components/` (or `Core/Components/` if shared across features).

5. **The design system is the only source of values**:
   - No font size, spacing, colour, radius, shadow, opacity, border width, duration or dimension is invented. Every value is a `DS.*` token or a `.textStyle(...)` step.
   - Tokens are generated from `design-system/tokens.json` by `scripts/ds-tokens-swift.py` into `Core/Design/Generated/`. **Never hand-edit `Generated/`** or `design-system/`; `Core/Design/DS+*.swift` only alias generated values. See `Core/Design/README.md`.
   - `scripts/ds-lint.sh` must be clean. A literal that has to stay ends in `// ds-lint:allow <reason>` quoting the README it came from.
   - Where the spec contradicts itself, the component README wins over older root-README prose; log every such call in `Core/Design/DS-GAPS.md`.

---

## 3. Placement Decision Matrix

When creating or moving a file, use this decision tree:

| Item Type | Scope | Placement |
| :--- | :--- | :--- |
| **Screen / Route View** | Primary navigation target | `NomNom/Features/<Feature>/Views/<ScreenName>View.swift` |
| **Feature Section / Card / Sheet** | Used within one feature | `NomNom/Features/<Feature>/Components/<SectionName>.swift` |
| **Feature Logic / Scoring** | Non-UI algorithm or state engine | `NomNom/Features/<Feature>/Engine/` or `Models/` |
| **Design-system component** | Has a README in `design-system/components/` | `NomNom/Core/Components/<Foundations\|Primitives\|Layout\|Composites>/<Name>.swift` |
| **Shared pattern the DS lacks** | Used or usable across $\ge 2$ features | `NomNom/Core/Components/Interim/<Name>.swift` + `Core/Design/DS-GAPS.md` entry |
| **Design token alias** | A value from `tokens.json` | `NomNom/Core/Design/DS+<Family>.swift` (generated values in `Generated/`, never hand-edited) |
| **Extension / Utility** | General type extensions | `NomNom/Core/Extensions/<Type>+<Functionality>.swift` |
| **Data Entity / Value Type** | App-wide data model | `NomNom/Domain/<ModelName>.swift` |
| **Store Mutation / Query** | Domain-specific backend logic | `NomNom/Services/FoodStore/FoodStore+<Domain>.swift` |

---

## 4. `FoodStore` Extension Pattern

Never add new domain methods directly into `FoodStore.swift`.
- `FoodStore.swift` contains only core `@Observable` state declarations and shared initialization.
- Group all async actions, database calls, and domain-specific mutations into `FoodStore+<Domain>.swift` files (one per domain — `Meals`, `Recipes`, `RecipeAI`, `RecipeDiscovery`, `RecipeSafeBets`, `RecipeSteps`, `RecipeFavorites`, `Parties`, `PartyFollowing`, `PartyInvites`, `PartyScores`, `Ratings`, `Health`, `Insights`, `Notifications`, `Inbox`, `MealInviteReminders`, `TableExplanation`, `ScoreInsight`, `RecipeTweaks`, `PartyRecipeNotes`, `Categories`, `Eaters`, `Profile`, `Loading`, `Errors`, `Preview`).
- When adding a new domain concept, create a new `FoodStore+<NewDomain>.swift` extension file rather than growing an existing one or `FoodStore.swift` itself.

---

## 5. Modal Sheet Dismissal & Confirmation Convention (Apple HIG Aligned)

Every modal sheet is a design-system **BottomSheet** (`design-system/components/BottomSheet/README.md`): `.dsSheet()` on its root for the `sheet` ground, `radius-4xl` corners and the DS grabber, and `SheetBody { … }` for the content padding and gaps. The close button sits on `.topBarLeading` alone (a system `xmark` on the bar's white glass circle, drawn by the modifiers below); any primary action (`+`, `checkmark` to save, `Next`) sits on `.topBarTrailing`.

### A. Intent Matrix

| Sheet Type | Purpose & Examples | Leading Action (`.topBarLeading`) | Trailing Action (`.topBarTrailing`) | Modifier |
| :--- | :--- | :--- | :--- | :--- |
| **Commit / Form / Editor** | Inputs, edits, ratings, filters (`MealEditorView`, `RecipeEditSheet`, `ProfileSheetView`, `RecipeFilterSheet`) | Close (discards the draft) | Checkmark, or a spinner while saving | `.sheetCommitToolbar` |
| **Multi-step, first step** | `CreateRecipeSheet`, `RecipeEditSheet`, `CreatePartySheet` | Close | "Next", disabled until the step is valid | `.sheetNextToolbar` |
| **Multi-step, middle step** | Pushed one-question steps (`RateStepView` in `RateMealSheet`); optional steps pin a `secondary ghost` "Skip" to the bottom | System back button | "Next" | `.stepNextToolbar` |
| **Multi-step, later step** | Pushed last steps (`RateReviewStep`, `MealDetailsStepView`, `RecipeDetailsStepView`, `PartySetupStepView`) | System back button | Checkmark or spinner; interactive dismiss disabled while saving | `.stepCommitToolbar` |
| **Media / Photo Viewer** | Full-screen photos with no state changes (`MediaViewerSheet`) | Close | *None* | `.mediaViewerStyle()` |
| **Note editor** | Full-height edit of one multi-line note, opened by `NoteField` (`NoteEditorSheet`) | Close (discards the draft) | Checkmark | `.sheetCommitToolbar` |
| **Read-only sheet** | Explanations, insight sheets (`PartyMemberInsightSheet`) | Close | *None* | `.sheetCloseToolbar()` |
| **Selection / Picker** | Choosing an item dismisses (`RecipePickerSheet`, `CuisinePickerSheet`) | Close | Optional primary action | `.sheetCancelToolbar()` |
| **Management / Overview** | Modal list overview (`PartyMembersSheet`) | Close | Optional primary action (`plus`) | `.sheetOverviewToolbar` |

---

### B. Centralized View Modifiers (`NomNom/Core/Extensions/View+SheetToolbars.swift`)

Never hand-write sheet toolbars, grabbers or sheet padding. **ALWAYS** use:

```swift
NavigationStack {
    SheetBody { /* sections */ }
        .screenTitle("Rate meal", displayMode: .inline)
        .sheetCommitToolbar(isSaving: isSaving, canSave: canSave, onCancel: nil) { save() }
}
.dsSheet()                                   // or .dsSheet(detents: [.medium, .large])

.sheetNextToolbar(canProceed: isValid) { path.append(.details) }
.stepNextToolbar(canProceed: isValid) { path.append(.next) }
.stepCommitToolbar(isSaving: isSaving, canSave: canSave) { save() }
.sheetCloseToolbar()                         // read-only sheets
.sheetCancelToolbar()                        // pickers
.sheetOverviewToolbar(primarySystemImage: "plus") { showingCreate = true }
.mediaViewerStyle()                          // photo viewers (dark chrome + close)
```

---

## 6. No Emojis & Strict Icon Minimalism

- **NEVER use emojis** for anything (UI elements, reactions, ratings, taste verdicts, member badges, food items, or status indicators).
- **Be very exclusive with icons**: Keep iconography minimal and intentional. Avoid scattering decorative SF Symbols across cards, rows, or buttons. Rely primarily on clean typography, precise labels, numbers, and curated colors. Use icons only when essential for unambiguous interaction (e.g., standard trailing toolbar checkmark, navigation back/chevron, camera/photo capture, close xmark on viewers).

---

## 7. Pattern Extrapolation & Composable Architecture

To prevent duplication and ensure high consistency:

1. **Extrapolate Repeated Patterns Immediately**:
   - Whenever a visual pattern, toolbar configuration, header presentation, navigation title style, or layout structure is repeated ($\ge 2$ times), **extrapolate it into a reusable component in `NomNom/Core/Components/` or a view modifier in `NomNom/Core/Extensions/`**.
   - Do NOT copy-paste styling modifiers, navigation bar attributes, or custom layout stacks across multiple views.

2. **Centralized Screen Navigation & Headers**:
   - Always use `.screenTitle(_ title: String, displayMode: NavigationBarItem.TitleDisplayMode = .large)` for screen/sheet titles.
   - Every screen and sheet opens with **one** `ScreenHeader(_:eyebrow:date:summary:avatar:avatarEdit:role:actions:)` (`design-system/components/ScreenHeader/README.md`). An editable avatar (camera badge, tap to take or pick a photo) is `avatarEdit: ScreenHeaderAvatarEdit(...)`, never a hand-built photo picker beside the header (DS-GAPS.md, "ScreenHeader avatar edit mode"). It is centred only by an `avatar`, `role: .tabRoot` (Meals, Recipes, Parties, which also carry a one-sentence summary) or `role: .moment` (sign-in, onboarding, the Pro paywall); otherwise leading. The eyebrow is ONE item (a category or the parent it lives in, never a date, product or flow name); dates go in `date:`; actions are at most two `ScreenHeaderAction`s, `md`, label only, on one row. There is no meta, facts, badges, align or size.
   - Small facts about the subject (time, method, servings, rotation) are `Facts(_:layout:)` (`.grid` / `.strip`), `text-primary` only; wrap it in a `Card` where the screen wants a surface.
   - **Screen anatomy** (root README): chrome · ScreenHeader · PhotoStrip · Facts · primary content · sections · destructive and account actions, `DS.Spacing.block` apart. Photos never sit above the header.
   - Text is set only with `.textStyle(_:tone:weight:italic:numeric:lines:align:)` (`serifXs…serifXl`, `sansXs…sansXl`; weight `.semibold` is opt-in). Never `.font(.system(size:))`, a font name or a raw size.

3. **Compose from `Core/Components`, in layers**:
   - **Foundations**: `DSAxes` (`DSVariant` primary/secondary/destructive/pro/warning/reaction, `DSAppearance` solid/soft/outline/ghost/elevated, `DSPaint`), `NomNomPreview`, photo plumbing.
   - **Primitives**: `AppButton` / `AppButtonLabel`, `Badge` (`.verdict`, `.delta`, `.rotation`, `.pro`, `.dishSummary`, `.rank`), `Avatar`, `Bar`, `ScoreValue`, `SectionHeader`, `AppToggle`, `Input`, `TextArea`.
   - **Layout**: `Card` (`layout: .block/.list`, `size`, `variant: .primary`, optional `action`), `DSSection` (label above content), `SectionCard` (label inside a card), `ScreenHeader`, `SwipeableListCard`.
   - **Composites**: `ListRow` (the one row: leading Avatar / PhotoCard `xs` / icon / rank, meta, value, trailing Badge / ScoreValue / AppButton / Toggle, chevron, unread), `EmptyState` (`screen` / `card` / `plain` / `row`), `Skeleton` (the one loading state: `list` / `card` / `text` / `row` bones in the content's shape, a caption for slow work; a spinner only inside a button the person pressed), `Facts`, `ScoreCard`, `PhotoCard` (owns the photo → cuisine → no-photo fallback), `PhotoStrip`, `RatingList`, `Timeline`, `RecipeCard`, `RecipeLinkCard`, `RecipeShelf`, `PartyCard`, `SegmentedBar`, `ValueStepper`, `LabeledPhotoCard`, `TasteScoreSelector`, the Pro language (`ProMark`, `ProCard`, `ProGate`, `.proView()`: a locked Pro block in a free view is a ProCard, a Pro-only screen is a ProView behind a ProGate), and the BottomSheet parts `SheetBody` / `SheetCard` / `SheetHero`.
   - Every list is `Card(layout: .list)` of `ListRow`s; never hand-draw dividers, capsules, avatars or thumbnails.
   - Each component follows its README in `design-system/components/<Name>/README.md`. Read it before changing the component.

4. **A pattern the DS lacks goes in `Core/Components/Interim/` + `DS-GAPS.md`; never hand-roll it**:
   - Build the interim component only from DS primitives and tokens, start the file with a `// DS-GAP: pending design system` header, and add an entry to `Core/Design/DS-GAPS.md` (section "Open gaps").
   - Today: `TrendChart`, `MediaViewerSheet`, `NameFieldsCard`, `PartyFormFields`, `VisibilityToggleCard`, `AccountActionsSection`, `PageMenu`, `ProLinkCard`, `PersonHeaderRow`, `NoteField` / `NoteEditorSheet`.
   - **Multi-line text in a form is always `NoteField`** (a row that opens `NoteEditorSheet`, like Apple Maps' "Add a Note"); never an inline `TextArea`. Fields have no border: `soft` (borderless fill) standalone, `plain` inside a card.

---

---

## 8. Button System (`AppButton`) — Rules & Usage Matrix

**ALL** action buttons in screens, sheets, cards, section headers, row accessories, and empty states **MUST** use `AppButton` (`NomNom/Core/Components/Primitives/AppButton.swift`), spec `design-system/components/AppButton/README.md`. No exemptions for view-body buttons. Controls that bring their own tap handling (`PhotosPicker`, `ShareLink`, `Menu`, `NavigationLink`) use `AppButtonLabel` as their label with `.buttonStyle(AppPressableButtonStyle())`.

### A. Axes

```swift
AppButton("Rate this meal", size: .lg, fullWidth: true) { … }                 // primary solid
AppButton("Resend", appearance: .soft, size: .sm) { … }
AppButton("Reset filters", variant: .secondary, appearance: .ghost) { … }
AppButton("Delete meal", icon: "trash", variant: .destructive, appearance: .outline) { … }
AppButton("Next", icon: "arrow.right", iconPosition: .end, isLoading: isSaving) { … }
AppButton(icon: "chevron.left", accessibilityLabel: "Back", variant: .secondary, appearance: .elevated) { … }
```

1. **`variant`** (colour role, default `.primary`):
   - **`.primary`**: `solid` is the one main commitment on a screen ("Log a meal", "Rate this meal"); one per view. `soft` is for supporting branded actions ("Resend", "Join dinner party").
   - **`.secondary`**: alternatives and utilities ("Use a different address", "Reset filters", "Skip step").
   - **`.destructive`**: irreversible actions only ("Delete meal", "Leave party", "Sign out"). Prefer `outline` or `ghost`, and confirm with an alert.
   - **`.pro`**: Nom Nom Pro CTAs only ("Unlock with Pro").
   - `.reaction(r)` is used only inside TasteScoreSelector, never as an action.
2. **`appearance`** (visual weight, default `.solid`): `solid` = role fill + `on-{role}`; `soft` = `{role}-soft` + `{role}-text`; `outline` = clear + `{role}-text` + `border-hairline` `line-control`; `ghost` = `{role}-text` only; `elevated` = `panel` + `shadow-xs` + `text-primary`, for floating controls over content.
3. **`size`** (default `.md`): `xs`, `sm` and `md` are all 44pt tall and differ in type step (`sans-xs` / `sans-sm` / `sans-md`) and side padding; `lg` is 48pt (`sans-lg`) for full-width screen-bottom actions. **No button is smaller than 44 × 44.**
4. **Icon-only**: `AppButton(icon:accessibilityLabel:…)` takes no size. Every icon-only button is the same 44pt circle.
5. **Options**: `icon` (SF Symbol string, `.asset`, `.image`) + `iconPosition` `.start` / `.end`; `fullWidth`; `isLoading` (a spinner replaces the icon and the tap is dropped; the button is not disabled). Disable with `.disabled(_:)` (`opacity-50`).
6. **Fixed**: label always semibold, sentence case; shape always a capsule; press is `opacity-70` only (a button never scales). Icons only where they remove ambiguity (camera, trash, plus, back, close, forward arrow).

### B. Platform Exceptions (Native Constraints)

Only these specific system-level APIs are exempt from `AppButton`:
1. **Alerts & Dialogs (`alert`, `confirmationDialog`)**: Must use native `Button("Title", role: ...)` primitives required by SwiftUI.
2. **System Menus & Swipes (`swipeActions`, `contextMenu`, `Menu`)**: Must use native `Button` primitives required by iOS system menus.
3. **Top-bar controls** (sheet and screen toolbars): system `Button`s handled by the sheet modifiers in Section 5. Every one is a `text-primary` glyph on the native white glass circle via `.barItemStyle()`; never the `primary` tint, never an AppButton.

---

## 9. Native Tool Usage & Direct Execution Over Manual Workarounds

- **Always Use Native Agent Tools Directly**:
  - Use provided tools (`run_command`, `replace_file_content`, `write_to_file`, `view_file`, `grep_search`, `find_by_name`, etc.) to execute tasks directly rather than instructing the user to do them manually.
  - **No Ad-Hoc Scripts for Standard Operations**: Do NOT write temporary shell scripts, Python runner scripts, or throwaway scratch scripts to perform tasks that standard tools or direct shell commands handle cleanly.
  - **Direct File Editing & Creation**: Always perform edits with `replace_file_content` and create new files with `write_to_file` directly. Do not use shell redirection tricks (e.g., `cat << EOF`, `echo ... > file`, sed/awk scripts) or ask the user to manually copy-paste code changes.
  - **Execute via `run_command`**: When builds, tests, migrations, checks, or package commands need to be run, execute them via `run_command` directly rather than expecting the user to switch terminals and run them manually.

---
 
## 10. Database Migrations & Local Seeding Protocol

- **STRICT LOCAL-ONLY SEEDING**:
  - **NEVER seed, reset, or run destructive test scripts against remote or production Supabase.**
  - Seed test data exists exclusively for local development in the Docker container (`supabase_db_food`).
  - Production / remote databases must ONLY receive safe schema migrations (`supabase db push` or clean migration scripts), NEVER test seeds or wipe scripts.

- **Automated Local Seed Script (`./scripts/seed.sh`)**:
  - **Do NOT manually engineer or split seed queries.**
  - To apply pending migrations and reseed local test data at any time, run:
    ```bash
    ./scripts/seed.sh
    ```
  - To completely reset and reseed local Postgres from scratch:
    ```bash
    ./scripts/seed.sh --reset
    ```

---

## 11. Branching & Releases

- **Feature PRs target the newest `release/*` branch, never `main`.** Find it with `git branch -r --list 'origin/release/*' | sort -V | tail -n 1`. New Superset workspaces set this as `gh pr create`'s default base (`.superset/setup.sh`); otherwise pass `--base release/<version>`.
- **Only release PRs (`release/*` → `main`) go into `main`.** The `Release gate` check fails anything else (Dependabot excepted).
- **No direct pushes** to `main` or `release/*`; GitHub rulesets require a PR for both.
- **CodeQL runs on release branches and `main` only**, not on feature PRs. The Swift job takes about 30 min, so a release PR into `main` waits for it.
- When a workspace needs work that is on the release branch but not yet on `main`, create it from the release branch (`superset ws create … --base-branch release/<version>`).

---

## 12. Summary Checklist Before Creating or Modifying Code

- [ ] Will this change cause the file to exceed ~200–250 lines? If yes, extract a component first.
- [ ] Is this new component or subview located in the correct `Components/` folder rather than inlined in a parent view?
- [ ] Are repeated UI structures or modifiers extrapolated into reusable composables?
- [ ] Is `NomNom/Domain/` kept clean of UI code and SwiftUI imports (unless raw type conformances require it)?
- [ ] Are store methods placed in the corresponding `FoodStore+<Domain>.swift` extension?
- [ ] Does every screen and sheet open with one `ScreenHeader` (no hand-built title stacks), follow the screen anatomy order (header before photos), and use `.screenTitle(...)` for navigation titles?
- [ ] Did you read `design-system/components/<Name>/README.md` for every component you touched or composed?
- [ ] Does every value come from a `DS.*` token or `.textStyle(...)`, and is `scripts/ds-lint.sh` clean?
- [ ] Is `scripts/ds-coverage.sh` clean? Is every new pattern with no DS equivalent in `DS-GAPS.md`, and did you name it to the user?
- [ ] Is the view composed from `Core/Components` (Card, ListRow, EmptyState, …)? Is a pattern the DS lacks in `Interim/` with a `DS-GAPS.md` entry, not hand-rolled?
- [ ] Is `Core/Design/Generated/` untouched (regenerated with `scripts/ds-tokens-swift.py` only)?
- [ ] Do modal sheets use `.dsSheet()`, `SheetBody` and one of the sheet toolbar modifiers (close on `.topBarLeading`, primary action on `.topBarTrailing`)?
- [ ] Are all action buttons in screens, sheets, cards, and sections using `AppButton` (or `AppButtonLabel` inside a picker, share link or menu) rather than raw `Button`?
- [ ] Are AppButton variants (`primary`, `secondary`, `destructive`, `pro`), appearances (`solid`, `soft`, `outline`, `ghost`, `elevated`) and sizes (`xs`, `sm`, `md`, `lg`) used according to Section 8?
- [ ] Are emojis completely avoided across all UI and data representations?
- [ ] Is iconography strictly minimal and purposeful rather than decorative?
- [ ] Are database seeds executed strictly against the local Docker instance via `./scripts/seed.sh`, never against production?
- [ ] Are native agent tools (`run_command`, `replace_file_content`, `write_to_file`, etc.) used directly instead of generating throwaway scripts or deferring actions manually?



