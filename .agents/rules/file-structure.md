# File & Folder Structure Rules

Guidelines to keep the Nom Nom codebase modular, cleanly organized, and prevent files from growing bloated.

## 1. Directory Structure

- `NomNom/App/`: App initialization & root view hierarchy (`RootTabView.swift`, `RootView.swift`, etc.).
- `NomNom/Features/<FeatureName>/`:
  - `Views/`: Screen-level views & navigation destinations (orchestration only).
  - `Components/`: Feature-specific sections, cards, sheets, pickers, and subviews.
  - `Engine/` or `Models/`: Feature-specific computation or non-UI logic (e.g. `Suggestions/Engine/`).
- `NomNom/Core/`:
  - `Components/`: Reusable, feature-agnostic design system primitives (`Chip`, `VerdictStrip`, `TastePicker`, etc.).
  - `Extensions/`: Foundation and SwiftUI extensions (`<Type>+<Feature>.swift`).
  - `Parsing/`: Formatters, parsers, and utilities.
- `NomNom/Domain/`: Pure data models and value entities (`Meal`, `Dish`, `Party`, `Reaction`, etc.) without UI dependencies.
- `NomNom/Services/`:
  - `FoodStore/`: State management partitioned across domain extensions (`FoodStore+Meals.swift`, `FoodStore+Dishes.swift`, etc.).
  - `Supabase/`: Backend integration and network clients.

## 2. File Size Limits & Decomposition

- **Max Target Length**: Aim for < 200 lines per file. Any file approaching 250–300 lines should have components extracted.
- **Single Responsibility**: Do not inline large `@ViewBuilder` sections (> 20 lines) or modal sheets at the bottom of views.
- **Component Extraction**: When adding a new UI card, section, or modal sheet, create a dedicated file in `NomNom/Features/<Feature>/Components/` (or `NomNom/Core/Components/` if shared).
- **Store Extensions**: Never append domain logic to `FoodStore.swift`; create or update the appropriate `FoodStore+<Domain>.swift` file.
