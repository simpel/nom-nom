import SwiftUI

/// Main tab — Recipes ("Nom Nom iOS" canvas): a ScreenHeader with no action (the tab is
/// for finding recipes; "New recipe" lives in the PageMenu and on My recipes), then the
/// Pro party card (AI picks, else safe bets), My favourites, My recipes, Popular recipes
/// and the cuisine categories.
struct RecipesView: View {
    @Environment(FoodStore.self) private var store

    @State private var showingCreateSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.block) {
                    ScreenHeader(
                        "Recipes",
                        summary: "Find something to cook, from party picks to what everyone loves.",
                        role: .tabRoot
                    )
                    .padding(.horizontal, DS.Spacing.gutter)

                    RecipesBrowseSections()
                }
                .padding(.top, DS.Spacing.s5)
                .padding(.bottom, DS.Spacing.s11)
            }
            .background(DS.Color.bg)
            .refreshable { await store.load() }
            .mainTabToolbar {
                Section {
                    Button("New recipe", systemImage: "plus") { showingCreateSheet = true }
                }
            }
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
