import SwiftUI

/// Main Tab — Recipes. Global discovery and category exploration hub, or personal recipes collection.
struct RecipesView: View {
    @Environment(FoodStore.self) private var store

    @State private var selectedTab: RecipeTab = .inspiration
    @State private var showingCreateSheet = false

    enum RecipeTab: String, CaseIterable, Identifiable {
        case inspiration = "Inspiration"
        case myRecipes = "My Recipes"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.sectionCompact) {
                    Picker("View", selection: $selectedTab) {
                        ForEach(RecipeTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, DS.Spacing.screenHorizontal)

                    switch selectedTab {
                    case .inspiration:
                        RecipeInspirationSection()
                    case .myRecipes:
                        MyRecipesSection(
                            recipes: store.myRecipes.sorted { $0.createdAt > $1.createdAt },
                            onCreateRecipe: { showingCreateSheet = true }
                        )
                    }
                }
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("Recipes")
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
