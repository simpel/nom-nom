# Nom Nom — Agent Guidelines & File/Folder Structure Rules

These instructions define how the Nom Nom codebase is structured and the rules to prevent files from growing bloated and unmaintainable.

---

## 1. Directory & Folder Architecture

This is a pnpm/Turborepo monorepo. Three apps under `apps/`, shared configs under `packages/`.
Every `NomNom/...` path elsewhere in this doc is shorthand for `apps/ios/NomNom/...`.

```
apps/
├── ios/NomNom/         # SwiftUI app
│   ├── App/            # App lifecycle, root navigation (RootTabView, RootView, NomNomApp)
│   ├── Features/       # Vertical slices: Auth, Calendar, Diary, Insights, Notifications,
│   │   │                 Parties, Recipes, Settings, Suggestions
│   │   ├── Components/ # Feature-specific subviews, cards, sheets, pickers
│   │   ├── Views/      # Screen-level views
│   │   └── Engine/     # Feature-specific non-UI logic where present (e.g. Suggestions/, Recipes/)
│   ├── Core/           # Shared, feature-agnostic primitives
│   │   ├── Components/ # Design system components (AppButton, Chip, VerdictStrip, SectionCard, etc.)
│   │   ├── Design/     # Design tokens
│   │   ├── Extensions/ # Foundation & SwiftUI extensions
│   │   ├── Fonts/      # Bundled font files + registry
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

---

## 3. Placement Decision Matrix

When creating or moving a file, use this decision tree:

| Item Type | Scope | Placement |
| :--- | :--- | :--- |
| **Screen / Route View** | Primary navigation target | `NomNom/Features/<Feature>/Views/<ScreenName>View.swift` |
| **Feature Section / Card / Sheet** | Used within one feature | `NomNom/Features/<Feature>/Components/<SectionName>.swift` |
| **Feature Logic / Scoring** | Non-UI algorithm or state engine | `NomNom/Features/<Feature>/Engine/` or `Models/` |
| **Reusable UI Primitive** | Used or usable across $\ge 2$ features | `NomNom/Core/Components/<ComponentName>.swift` |
| **Extension / Utility** | General type extensions | `NomNom/Core/Extensions/<Type>+<Functionality>.swift` |
| **Data Entity / Value Type** | App-wide data model | `NomNom/Domain/<ModelName>.swift` |
| **Store Mutation / Query** | Domain-specific backend logic | `NomNom/Services/FoodStore/FoodStore+<Domain>.swift` |

---

## 4. `FoodStore` Extension Pattern

Never add new domain methods directly into `FoodStore.swift`.
- `FoodStore.swift` contains only core `@Observable` state declarations and shared initialization.
- Group all async actions, database calls, and domain-specific mutations into `FoodStore+<Domain>.swift` files (one per domain — `Meals`, `Recipes`, `RecipeAI`, `RecipeDiscovery`, `RecipeFavorites`, `Parties`, `PartyFollowing`, `PartyInvites`, `PartyScores`, `Ratings`, `Health`, `Insights`, `Notifications`, `Inbox`, `Categories`, `Eaters`, `Profile`, `Loading`, `Errors`, `Preview`).
- When adding a new domain concept, create a new `FoodStore+<NewDomain>.swift` extension file rather than growing an existing one or `FoodStore.swift` itself.

---

## 5. Modal Sheet Dismissal & Confirmation Convention (Apple HIG Aligned)

Every modal sheet must place the close button ("X") consistently on `.topBarLeading` alone, with any primary or secondary actions (e.g. `+`, `checkmark` to save, `Next`, or `Edit`) placed on the opposite side (`.topBarTrailing`):

### A. Intent Matrix

| Sheet Type | Purpose & Examples | Leading Action (`.topBarLeading`) | Trailing Action (`.topBarTrailing`) |
| :--- | :--- | :--- | :--- |
| **Commit / Form / Editor** | User inputs, edits, ratings, or filters (`MealEditorView`, `MealRatingSheet`, `RecipeEditSheet`, `CreatePartySheet`, `ProfileSheetView`, `SuggestionFiltersView`) | `Image(systemName: "xmark")` (discards uncommitted draft state, alone) | `Image(systemName: "checkmark")` (saves / confirms / commits) or `ProgressView().controlSize(.small)` during async save |
| **Media / Photo Viewer / Lightbox** | Inspecting photos, galleries, full-screen documents with NO state changes (`MealPhotoViewerSheet`, `MealGalleryViewerSheet`, `RecipePhotoViewerSheet`) | `Image(systemName: "xmark")` with `.accessibilityLabel("Close")` (alone) | *None* |
| **Selection / Entity Picker** | Picking an item (`RecipePickerSheet`) | `Image(systemName: "xmark")` (alone) | Optional primary action (e.g. `+` `Image(systemName: "plus")`) |
| **Management / List Overview** | Modal navigation overview (`PartyListView`, `HouseholdMembersSheet`) | `Image(systemName: "xmark")` (alone when modal) | Optional primary action (e.g. `+` `Image(systemName: "plus")`) |

---

### B. Centralized View Modifiers (`NomNom/Core/Extensions/`)

Instead of hand-writing repetitive toolbar boilerplate, **ALWAYS** use the centralized view modifiers:

1. **Commit / Form Sheets**:
   ```swift
   .sheetCommitToolbar(
       isSaving: isSaving,
       canSave: canSave,
       onCancel: { /* optional custom discard handler */ },
       onSave: { save() }
   )
   ```

2. **Media Viewers & Lightboxes**:
   ```swift
   .mediaViewerStyle()
   // Or standalone: .sheetCloseToolbar(color: .white)
   ```

3. **Pickers (Item Selection Dismisses)**:
   ```swift
   .sheetCancelToolbar()
   ```

4. **Management / Overview Sheets**:
   ```swift
   .sheetOverviewToolbar(
       primarySystemImage: "plus",
       onPrimaryAction: { showingCreate = true }
   )
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
   - Use `PageHeader(title:subtitle:)` for hero/in-body narrative titles.
   - Never hardcode raw point sizes or font names in individual views — reference `AppTypography` or semantic typography tokens.

---

---

## 8. Button System (`AppButton`) — Rules & Usage Matrix

**ALL** action buttons in screens, sheets, cards, section headers, row accessories, and empty states **MUST** use the centralized `AppButton` component (`NomNom/Core/Components/AppButton.swift`). No exemptions for view-body buttons.

### A. Dimensions & Options

1. **`variant` (Intent & Hierarchy)**:
   - **`.primary`**: The single primary call-to-action on a screen or modal. Brand accent background in `.normal` style, white text. (*Only one primary normal button per view*).
   - **`.secondary`**: Supporting actions paired with a primary CTA, or branded actions (e.g. "Send", "Resend", "Follow"). Uses soft accent background (`DS.Color.accentSoft`) and accent text (`DS.Color.accentText`).
   - **`.neutral`**: Alternative paths, utility actions, dismissive or non-accented secondary flows (e.g. "Use a different address", "Reset Filters", "Skip Step", "Clear Search"). Uses high-contrast text (`DS.Color.textSecondary` in ghost style, 8.3:1+ contrast) and neutral styling.
   - **`.destructive`**: Irreversible or high-consequence actions (e.g. "Delete Meal", "Leave Party", "Sign out", "Delete account"). System red styling.

2. **`style` (Visual Weight)**:
   - **`.normal`**: Solid filled background. Highest visual weight for primary commitments.
   - **`.outlined`**: Transparent background with a distinct 1.5pt border. Medium priority for card actions, secondary tools, or adjacent buttons.
   - **`.ghost`**: 100% transparent background (`Color.clear`), no border. Lowest visual weight for alternatives, skips, and tertiary links.

3. **`size` (Context & Touch Targets)**:
   - **`.xl` (50pt)**: Full-width screen-bottom actions, auth flows, hero forms (matches 50pt input field height). `.headline.weight(.semibold)`.
   - **`.md` (42pt)**: Standard screen section CTAs, empty-state callouts, dialog action buttons, card footers. `.callout.weight(.semibold)`.
   - **`.sm` (34pt)**: Compact row actions (e.g. "Resend" in member row, "Edit" in section headers, follow/unfollow pill). `.subheadline.weight(.semibold)`.

4. **Typography & Shape**:
   - **Font weight**: Every button variant/style **MUST** maintain `Font.weight(.semibold)` for visual consistency.
   - **Shape**: Always a clean `Capsule()` boundary.

5. **Icon Support (`AppButtonIcon`)**:
   - Accepts string literals (`icon: "plus"`), explicit SF symbols (`icon: .system("camera")`), named asset images (`icon: .asset("badge")`), or custom `Image`s (`icon: .image(...)`).
   - Placement: `iconPosition: .leading` (default) or `.trailing` (e.g. `iconPosition: .trailing` for forward flow arrows).
   - Icon-only buttons: omit `title` to get a circular button sized to `size.height` (34pt, 42pt, or 50pt).


### B. Platform Exceptions (Native Constraints)

Only these specific system-level APIs are exempt from `AppButton`:
1. **Alerts & Dialogs (`alert`, `confirmationDialog`)**: Must use native `Button("Title", role: ...)` primitives required by SwiftUI.
2. **System Menus & Swipes (`swipeActions`, `contextMenu`, `Menu`)**: Must use native `Button` primitives required by iOS system menus.
3. **Sheet Navigation Toolbars**: Handled by `.sheetCommitToolbar` / `.sheetOverviewToolbar` per Section 5.

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

## 11. Summary Checklist Before Creating or Modifying Code

- [ ] Will this change cause the file to exceed ~200–250 lines? If yes, extract a component first.
- [ ] Is this new component or subview located in the correct `Components/` folder rather than inlined in a parent view?
- [ ] Are repeated UI structures or modifiers extrapolated into reusable composables?
- [ ] Is `NomNom/Domain/` kept clean of UI code and SwiftUI imports (unless raw type conformances require it)?
- [ ] Are store methods placed in the corresponding `FoodStore+<Domain>.swift` extension?
- [ ] Do screens use `.screenTitle(...)` and `PageHeader` rather than ad-hoc navigation/header modifiers?
- [ ] Do modal sheets place the close button (`Image(systemName: "xmark")`) on `.topBarLeading` alone?
- [ ] Are primary actions (`+`, `checkmark` save, Next, Edit) placed on `.topBarTrailing` opposite to the close button?
- [ ] Are all action buttons in screens, sheets, cards, and sections using `AppButton` rather than raw `Button`?
- [ ] Are button variants (`primary`, `secondary`, `neutral`, `destructive`), styles (`normal`, `outlined`, `ghost`), and sizes (`sm`, `md`, `xl`) used according to Section 8?
- [ ] Are emojis completely avoided across all UI and data representations?
- [ ] Is iconography strictly minimal and purposeful rather than decorative?
- [ ] Are database seeds executed strictly against the local Docker instance via `./scripts/seed.sh`, never against production?



