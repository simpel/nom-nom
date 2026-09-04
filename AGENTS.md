# Nom Nom — Agent Guidelines & File/Folder Structure Rules

These instructions define how the Nom Nom codebase is structured and the rules to prevent files from growing bloated and unmaintainable.

---

## 1. Directory & Folder Architecture

All Swift source code lives under `NomNom/` and is divided into clear layers:

```
NomNom/
├── App/                # App lifecycle, Root navigation (RootTabView, RootView, NomNomApp)
├── Features/           # Vertical slices of user-facing features
│   ├── Auth/           # Sign-in, verification, auth controller & dev helpers
│   ├── Calendar/       # Calendar month grid and date meal listings
│   │   ├── Components/ # Calendar-specific subviews, cells, headers
│   │   └── Views/      # Primary screen-level calendar views
│   ├── Diary/          # Meal log, dish detail, meal detail, meal editor
│   │   ├── Components/ # Sections, cards, sheets, pickers specific to Diary/Meals
│   │   └── Views/      # Screen-level views (MealsView, MealDetailView, etc.)
│   ├── Settings/       # User profile, parties, preferences
│   │   ├── Components/ # Party cards, member rows, invite sheets
│   │   └── Views/      # Screen-level settings views
│   └── Suggestions/    # "What to eat" recommendation engine & UI
│       ├── Components/ # Filter sheets, suggestion cards, score breakdowns
│       ├── Engine/     # Scoring, ranking algorithms, filtering logic
│       └── Views/      # Screen-level suggestion views
├── Core/               # Shared, feature-agnostic reusable primitives
│   ├── Components/     # Design system components (Chip, VerdictStrip, TastePicker, CameraPicker, etc.)
│   ├── Extensions/     # Foundation & SwiftUI extensions (String+Matching, Date+Formatting, etc.)
│   └── Parsing/        # Parsers, formatters, text helpers
├── Domain/             # Core models and entities (Meal, Dish, Party, Profile, Reaction, etc.) — NO UI code
└── Services/           # Backend, networking, and data store
    ├── FoodStore/      # FoodStore split into domain extensions (FoodStore+Dishes, FoodStore+Meals, etc.)
    └── Supabase/       # Supabase client configuration and DTOs
supabase/
├── migrations/         # SQL migration scripts
└── functions/          # Deno/Edge functions (e.g., invite notifications)
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
- Group all async actions, database calls, and domain-specific mutations into `FoodStore+<Domain>.swift` files:
  - `FoodStore+Meals.swift`
  - `FoodStore+Dishes.swift`
  - `FoodStore+Parties.swift`
  - `FoodStore+Ratings.swift`
  - `FoodStore+Inbox.swift`
  - `FoodStore+Profile.swift`
  - `FoodStore+Loading.swift`
- When adding a new domain concept or feature domain, create a new `FoodStore+<NewDomain>.swift` extension file.

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

## 8. Summary Checklist Before Creating or Modifying Code

- [ ] Will this change cause the file to exceed ~200–250 lines? If yes, extract a component first.
- [ ] Is this new component or subview located in the correct `Components/` folder rather than inlined in a parent view?
- [ ] Are repeated UI structures or modifiers extrapolated into reusable composables?
- [ ] Is `NomNom/Domain/` kept clean of UI code and SwiftUI imports (unless raw type conformances require it)?
- [ ] Are store methods placed in the corresponding `FoodStore+<Domain>.swift` extension?
- [ ] Do screens use `.screenTitle(...)` and `PageHeader` rather than ad-hoc navigation/header modifiers?
- [ ] Do modal sheets place the close button (`Image(systemName: "xmark")`) on `.topBarLeading` alone?
- [ ] Are primary actions (`+`, `checkmark` save, Next, Edit) placed on `.topBarTrailing` opposite to the close button?
- [ ] Are emojis completely avoided across all UI and data representations?
- [ ] Is iconography strictly minimal and purposeful rather than decorative?


