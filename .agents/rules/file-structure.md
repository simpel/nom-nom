# File & Folder Structure Rules

Guidelines to keep the Nom Nom codebase modular, cleanly organized, and prevent files from growing bloated.

Monorepo: `apps/ios` (SwiftUI), `apps/web` (Next.js, incl. `/admin`), `apps/supabase` (migrations + Edge Functions), `packages/*` (shared configs). Paths below are relative to `apps/ios/NomNom/`.

## 1. Directory Structure

- `App/`: App initialization & root view hierarchy (`RootTabView.swift`, `RootView.swift`, etc.).
- `Features/<FeatureName>/` (Auth, Calendar, Diary, Insights, Notifications, Parties, Recipes, Settings, Suggestions):
  - `Views/`: Screen-level views & navigation destinations (orchestration only).
  - `Components/`: Feature-specific sections, cards, sheets, pickers, and subviews.
  - `Engine/`: Feature-specific computation or non-UI logic, where present (e.g. `Suggestions/Engine/`, `Recipes/Engine/`).
- `Core/`:
  - `Components/`: Reusable, feature-agnostic design system primitives (`AppButton`, `Chip`, `VerdictStrip`, `SectionCard`, etc.).
  - `Design/`: Design tokens.
  - `Extensions/`: Foundation and SwiftUI extensions (`<Type>+<Feature>.swift`).
  - `Fonts/`: Bundled font files + registry.
  - `Parsing/`: Formatters, parsers, and utilities.
- `Domain/`: Pure data models and value entities (`Meal`, `Recipe`, `Party`, `Reaction`, `HealthIndex`, etc.) without UI dependencies.
- `Services/`:
  - `FoodStore/`: State management partitioned across domain extensions (`FoodStore+Meals.swift`, `FoodStore+Recipes.swift`, etc.).
  - `Supabase/`: Backend integration and network clients.
  - `Billing/`: RevenueCat / subscription config.

## 2. File Size Limits & Decomposition

- **Max Target Length**: Aim for < 200 lines per file. Any file approaching 250–300 lines should have components extracted.
- **Single Responsibility**: Do not inline large `@ViewBuilder` sections (> 20 lines) or modal sheets at the bottom of views.
- **Component Extraction**: When adding a new UI card, section, or modal sheet, create a dedicated file in `Features/<Feature>/Components/` (or `Core/Components/` if shared).
- **Store Extensions**: Never append domain logic to `FoodStore.swift`; create or update the appropriate `FoodStore+<Domain>.swift` file.
