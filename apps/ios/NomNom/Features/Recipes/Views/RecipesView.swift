import SwiftUI

/// Main tab — Recipes ("Nom Nom iOS" canvas): the PageHeader with the party as eyebrow
/// and a search field, the Pro "Recommended for you" shelf, then My favourites, My
/// recipes (See all), Safe bets for the party, Popular everywhere and the cuisine
/// categories. Typing in the field swaps the shelves for matching recipes.
struct RecipesView: View {
    @Environment(FoodStore.self) private var store

    @State private var showingCreateSheet = false
    @State private var query = ""

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.block) {
                    VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                        PageHeader("Recipes", eyebrow: store.currentParty?.name)
                        Input("Search recipes", text: $query, leadingIcon: "magnifyingglass", clearable: true)
                    }
                    .padding(.horizontal, DS.Spacing.gutter)

                    if trimmedQuery.isEmpty {
                        RecipesBrowseSections()
                    } else {
                        RecipesSearchResults(query: trimmedQuery)
                    }
                }
                .padding(.top, DS.Spacing.s5)
                .padding(.bottom, DS.Spacing.s11)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(DS.Color.bg)
            .refreshable { await store.load() }
            .mainTabToolbar(addAccessibilityLabel: "New recipe") { showingCreateSheet = true }
            .sheet(isPresented: $showingCreateSheet) {
                CreateRecipeSheet()
            }
        }
    }
}

#Preview {
    NomNomPreview(inNavigationStack: false) {
        RecipesView()
    }
}
