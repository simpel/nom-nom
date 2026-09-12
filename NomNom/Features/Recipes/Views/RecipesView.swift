import SwiftUI

/// Main Tab — Recipes. Global discovery and category exploration hub, or personal recipes collection.
struct RecipesView: View {
    @Environment(FoodStore.self) private var store

    @State private var selectedTab: RecipeTab = .favourites
    @State private var showingCreateSheet = false

    enum RecipeTab: String, CaseIterable, Identifiable {
        case favourites = "Favourites"
        case myRecipes = "My Recipes"
        case inspiration = "Inspiration"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.sectionCompact) {
                    PageHeading(title: "Recipes", actionTitle: "Add recipe") {
                        showingCreateSheet = true
                    }
                    .padding(.horizontal, DS.Spacing.screenHorizontal)

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
                        .pickerStyle(.segmented)
                        .padding(.horizontal, DS.Spacing.screenHorizontal)

                        switch resolvedTab {
                        case .favourites:
                            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                                HStack {
                                    Text("\(store.favoriteRecipes.count) recipe\(store.favoriteRecipes.count == 1 ? "" : "s")")
                                        .font(.caption.weight(.medium))
                                        .monospacedDigit()
                                        .foregroundStyle(DS.Color.textSecondary)
                                    Spacer()
                                }
                                .padding(.horizontal, DS.Spacing.screenHorizontal)
                                .padding(.vertical, 4)
                                
                                MinimalRecipeGrid(recipes: store.favoriteRecipes.sorted { $0.createdAt > $1.createdAt })
                            }
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
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
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
