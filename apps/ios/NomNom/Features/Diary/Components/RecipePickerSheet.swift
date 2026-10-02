import SwiftUI

/// Searchable sheet to pick an existing recipe or create a new one.
/// Visually aligned with the Recipes main tab with curated horizontal shelves and category exploration.
struct RecipePickerSheet: View {
    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var onSelectExistingRecipe: (Recipe) -> Void
    var onSelectNewRecipe: (String) -> Void

    init(onSelectExistingRecipe: @escaping (Recipe) -> Void, onSelectNewRecipe: @escaping (String) -> Void) {
        self.onSelectExistingRecipe = onSelectExistingRecipe
        self.onSelectNewRecipe = onSelectNewRecipe
    }

    // Compatibility init
    init(onSelectExistingDish: @escaping (Recipe) -> Void, onSelectNewDish: @escaping (String) -> Void) {
        self.onSelectExistingRecipe = onSelectExistingDish
        self.onSelectNewRecipe = onSelectNewDish
    }

    @State private var searchText = ""
    @State private var showingCreateRecipeSheet = false

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var matchingRecipes: [Recipe] {
        guard !trimmedSearch.isEmpty else { return [] }
        let suggestions = DishRepository.suggestions(
            for: trimmedSearch,
            in: store.recipes,
            history: store.dishHistory,
            favoriteIDs: store.favoriteRecipeIDs,
            limit: 40
        )
        let resolved = suggestions.compactMap { store.recipe($0.dishID) }
        let favorites = resolved.filter { store.isFavorite(recipe: $0) }
        let nonFavorites = resolved.filter { !store.isFavorite(recipe: $0) }
        return favorites + nonFavorites
    }

    private var exactMatchExists: Bool {
        let key = trimmedSearch.normalizedForMatching
        guard !key.isEmpty else { return false }
        return store.recipes.contains { $0.normalizedName == key }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if trimmedSearch.isEmpty {
                    idleContent
                } else {
                    searchContent
                }
            }
            .background(DS.Color.sheet)
            .screenTitle("Pick a Recipe")
            .searchable(text: $searchText, prompt: "Search or type new recipe")
            .sheetOverviewToolbar(primarySystemImage: "plus", onPrimaryAction: {
                showingCreateRecipeSheet = true
            })
            .sheet(isPresented: $showingCreateRecipeSheet) {
                CreateRecipeSheet(initialName: trimmedSearch) { newRecipe in
                    onSelectExistingRecipe(newRecipe)
                    dismiss()
                }
            }
        }
        .dsSheet()
    }

    // MARK: - Idle Mode Content

    private var idleContent: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.block) {
            RecommendedForYouShelf(onSelect: selectRecipe)
            RecipeShelf("Favourites", recipes: store.favoriteRecipes, onSelect: selectRecipe)
            RecipeShelf("Recent & frequent", recipes: store.recentAndFrequentRecipes, onSelect: selectRecipe)
            RecipeShelf("Past favourites", recipes: store.pastFavoriteRecipes, onSelect: selectRecipe)
            RecipeShelf("Popular recipes", recipes: store.popularRecipes, onSelect: selectRecipe)
            RecipeCategoryGridSection(onSelectRecipe: selectRecipe)

            if store.recipes.isEmpty {
                EmptyState(
                    "No recipes yet",
                    message: "Type the name of what you cooked to create your first recipe."
                )
            }
        }
        .padding(.horizontal, DS.Spacing.gutter)
        .padding(.top, DS.Spacing.s5)
        .padding(.bottom, DS.Spacing.s11)
    }

    // MARK: - Search Mode Content

    private var searchContent: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.block) {
            if !exactMatchExists {
                Card(layout: .list) {
                    ListRow("Add \u{201C}\(trimmedSearch)\u{201D}", meta: "Create as a new recipe", leading: .icon("plus")) {
                        onSelectNewRecipe(trimmedSearch)
                        dismiss()
                    }
                }
                .padding(.horizontal, DS.Spacing.gutter)
            }

            if !matchingRecipes.isEmpty {
                VStack(alignment: .leading, spacing: DS.Spacing.s2_5) {
                    SectionHeader(title: "Matching Recipes", trailing: "\(matchingRecipes.count) found")
                        .padding(.horizontal, DS.Spacing.gutter)
                    MinimalRecipeGrid(recipes: matchingRecipes, onSelect: selectRecipe)
                }
            } else if exactMatchExists {
                // README case "Search found nothing"; the only way out is editing the search.
                EmptyState(
                    "No recipes match \u{2018}\(trimmedSearch)\u{2019}",
                    message: "Try a shorter search."
                )
                .padding(.horizontal, DS.Spacing.gutter)
            }
        }
        .padding(.top, DS.Spacing.s5)
        .padding(.bottom, DS.Spacing.s11)
    }

    private func selectRecipe(_ recipe: Recipe) {
        onSelectExistingRecipe(recipe)
        dismiss()
    }
}

typealias DishPickerSheet = RecipePickerSheet
