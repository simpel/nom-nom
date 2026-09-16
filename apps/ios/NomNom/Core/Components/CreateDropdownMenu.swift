import SwiftUI

/// Standard top-bar creation dropdown menu triggered by the '+' icon.
/// Surfaces choices to create a Meal, Recipe, or Dinner Party with direct sheet presentations.
struct CreateDropdownMenu: View {
    @State private var activeSheet: CreateTarget?

    private enum CreateTarget: String, Identifiable {
        case meal
        case recipe
        case party

        var id: String { rawValue }
    }

    var body: some View {
        Menu {
            Button {
                activeSheet = .meal
            } label: {
                Label("Meal", systemImage: "fork.knife")
            }

            Button {
                activeSheet = .recipe
            } label: {
                Label("Recipe", systemImage: "book.pages")
            }

            Button {
                activeSheet = .party
            } label: {
                Label("Dinner party", systemImage: "person.2")
            }
        } label: {
            Image(systemName: "plus")
                .fontWeight(.semibold)
        }
        .accessibilityLabel("Create")
        .sheet(item: $activeSheet) { target in
            switch target {
            case .meal:
                MealEditorView()
            case .recipe:
                CreateRecipeSheet()
            case .party:
                CreatePartySheet()
            }
        }
    }
}
