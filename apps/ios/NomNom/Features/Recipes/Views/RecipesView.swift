import SwiftUI

/// Main Tab — Recipes. Global discovery and category exploration hub, or personal recipes collection.
struct RecipesView: View {
    @Environment(FoodStore.self) private var store

    @State private var selectedTab: RecipeTab = .favourites
    @State private var showingCreateSheet = false

    enum RecipeTab: String, CaseIterable, Identifiable {
        case favourites = "Favourites"
        case myRecipes = "My recipes"
        case inspiration = "Inspiration"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.s6) {
                    PageHeader("Recipes", actions: [
                        EmptyStateAction("Add recipe", icon: "plus") { showingCreateSheet = true }
                    ])
                    .padding(.horizontal, DS.Spacing.gutter)

                    if store.myRecipes.isEmpty {
                        RecipeInspirationSection()
                    } else {
                        let availableTabs: [RecipeTab] = store.favoriteRecipes.isEmpty ? [.myRecipes, .inspiration] : [.favourites, .myRecipes, .inspiration]
                        let resolvedTab: RecipeTab = availableTabs.contains(selectedTab) ? selectedTab : availableTabs.first!

                        Picker("View", selection: Binding(
                            get: { resolvedTab },
                            set: { selectedTab = $0 }
                        )) {
                            ForEach(availableTabs) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        // A native segmented control: the DS has no tab switcher
                        // (SegmentedBar is a meter).
                        .pickerStyle(.segmented)
                        .padding(.horizontal, DS.Spacing.gutter)

                        switch resolvedTab {
                        case .favourites:
                            MinimalRecipeGrid(
                                recipes: store.favoriteRecipes.sorted { $0.createdAt > $1.createdAt },
                                title: "Favourites"
                            )
                        case .inspiration:
                            RecipeInspirationSection()
                        case .myRecipes:
                            MyRecipesSection(
                                recipes: store.myRecipes.sorted { $0.createdAt > $1.createdAt },
                                onCreateRecipe: { showingCreateSheet = true }
                            )
                        }
                    }
                }
                .padding(.top, DS.Spacing.s5)
                .padding(.bottom, DS.Spacing.s11)
            }
            .background(DS.Color.bg)
            .refreshable {
                await store.load()
            }
            .mainTabToolbar()
            .sheet(isPresented: $showingCreateSheet) {
                CreateRecipeSheet()
            }
        }
    }
}

#Preview {
    NomNomPreview {
        RecipesView()
    }
}
