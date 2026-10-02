import SwiftUI

/// What the Recipes tab's search field finds: the same ranking as the Search tab
/// (`DishRepository.suggestions`) as a two-column grid, or an EmptyState.
struct RecipesSearchResults: View {
    let query: String

    @Environment(FoodStore.self) private var store

    private var results: [Recipe] {
        DishRepository.suggestions(
            for: query,
            in: store.recipes,
            history: store.dishHistory,
            favoriteIDs: store.favoriteRecipeIDs,
            limit: 50
        )
        .compactMap { store.recipe($0.dishID) }
    }

    var body: some View {
        if results.isEmpty {
            EmptyState(
                "Nothing called \u{201C}\(query)\u{201D}",
                message: "Try a dish, an ingredient or a cuisine.",
                layout: .card
            )
            .padding(.horizontal, DS.Spacing.gutter)
        } else {
            MinimalRecipeGrid(recipes: results, title: "Results", onNavigate: { _ in
                SearchHistoryStore.shared.addQuery(query)
            })
        }
    }
}
