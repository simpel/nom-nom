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
            .background(DS.Color.bg)
            .screenTitle("Pick a Recipe")
            .searchable(text: $searchText, prompt: "Search or type new recipe")
            .sheetCancelToolbar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateRecipeSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Create Recipe")
                }
            }
            .sheet(isPresented: $showingCreateRecipeSheet) {
                CreateRecipeSheet(initialName: trimmedSearch) { newRecipe in
                    onSelectExistingRecipe(newRecipe)
                    dismiss()
                }
            }
        }
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
                ContentUnavailableView {
                    Label("No recipes yet", systemImage: "fork.knife")
                } description: {
                    Text("Type the name of what you cooked to create your first recipe.")
                }
                .padding(.top, DS.Spacing.s10)
            }
        }
        .padding(.horizontal, DS.Spacing.gutter)
        .padding(.top, DS.Spacing.screenTop)
        .padding(.bottom, DS.Spacing.screenBottom)
    }

    // MARK: - Search Mode Content

    private var searchContent: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.section) {
            if !exactMatchExists {
                Card(spacing: DS.Spacing.s0_5, action: {
                    onSelectNewRecipe(trimmedSearch)
                    dismiss()
                }) {
                    Text("Add “\(trimmedSearch)”").textStyle(.sansMd, weight: .semibold)
                    Text("Create as a new recipe").textStyle(.sansSm, tone: .secondary)
                }
                .padding(.horizontal, DS.Spacing.gutter)
            }

            if !matchingRecipes.isEmpty {
                VStack(alignment: .leading, spacing: DS.Spacing.s2_5) {
                    SectionHeader("Matching Recipes", trailingText: "\(matchingRecipes.count) found")
                    MinimalRecipeGrid(recipes: matchingRecipes, onSelect: selectRecipe)
                }
            } else if exactMatchExists {
                ContentUnavailableView {
                    Label("No matching recipes", systemImage: "magnifyingglass")
                } description: {
                    Text("No recipes match “\(trimmedSearch)”.")
                }
                .padding(.top, DS.Spacing.s10)
            }
        }
        .padding(.top, DS.Spacing.screenTop)
        .padding(.bottom, DS.Spacing.screenBottom)
    }

    private func selectRecipe(_ recipe: Recipe) {
        onSelectExistingRecipe(recipe)
        dismiss()
    }
}

typealias DishPickerSheet = RecipePickerSheet
