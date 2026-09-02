import SwiftUI

/// Main Tab — Recipes. Global discovery across all dinner parties and kitchens.
struct RecipesView: View {
    @Environment(FoodStore.self) private var store

    @State private var searchText = ""
    @State private var filterTab: RecipeFilterTab = .popular
    @State private var selectedCuisine: String?
    @State private var showingCreateSheet = false

    enum RecipeFilterTab: String, CaseIterable, Identifiable {
        case popular = "Popular"
        case myRecipes = "My Recipes"
        case recent = "Recent"
        case all = "All"

        var id: String { rawValue }
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var baseFilteredRecipes: [Recipe] {
        switch filterTab {
        case .popular:
            return store.popularRecipes
        case .myRecipes:
            return store.myRecipes
        case .recent:
            return store.recentRecipes
        case .all:
            return store.recipes.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }

    private var cuisineFilteredRecipes: [Recipe] {
        guard let cuisine = selectedCuisine?.lowercased() else { return baseFilteredRecipes }
        return baseFilteredRecipes.filter {
            $0.cuisine?.lowercased() == cuisine ||
            $0.tags.contains { $0.lowercased() == cuisine }
        }
    }

    private var displayedRecipes: [Recipe] {
        if trimmedSearch.isEmpty {
            return cuisineFilteredRecipes
        }

        let suggestions = DishRepository.suggestions(
            for: trimmedSearch,
            in: cuisineFilteredRecipes,
            history: store.dishHistory,
            limit: 50
        )
        return suggestions.compactMap { store.recipe($0.dishID) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Picker("Filter", selection: $filterTab) {
                        ForEach(RecipeFilterTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)

                    CuisineFilterStrip(selectedCuisine: $selectedCuisine)
                }
                .padding(.top, 8)
                .padding(.bottom, 6)
                .background(DS.Color.bg)

                Group {
                    if store.recipes.isEmpty {
                        ContentUnavailableView {
                            Label("No recipes yet", systemImage: "fork.knife")
                        } description: {
                            Text("Create your first recipe to start building your kitchen collection.")
                        } actions: {
                            Button("Create Recipe") {
                                showingCreateSheet = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else if displayedRecipes.isEmpty {
                        ContentUnavailableView {
                            Label("No matching recipes", systemImage: "magnifyingglass")
                        } description: {
                            Text("Try clearing search or changing your kitchen filter.")
                        } actions: {
                            Button("Reset Filters") {
                                searchText = ""
                                selectedCuisine = nil
                                filterTab = .popular
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        List {
                            Section {
                                ForEach(displayedRecipes) { recipe in
                                    NavigationLink {
                                        RecipeDetailView(recipeID: recipe.id)
                                    } label: {
                                        RecipeRowCard(recipe: recipe)
                                    }
                                }
                            } header: {
                                Text("\(displayedRecipes.count) recipe\(displayedRecipes.count == 1 ? "" : "s")")
                                    .monospacedDigit()
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .background(DS.Color.bg)
            .screenTitle("Recipes")
            .searchable(text: $searchText, prompt: "Search recipes, tags, or kitchens")
            .refreshable {
                await store.load()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Create Recipe")
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateRecipeSheet(initialName: trimmedSearch)
            }
        }
    }
}

#Preview {
    NomNomPreview {
        RecipesView()
    }
}
