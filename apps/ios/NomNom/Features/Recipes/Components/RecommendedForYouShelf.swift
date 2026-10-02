import SwiftUI

/// Pro-gated RecipeShelf of `SuggestionEngine`-ranked recipes, shown at the top of
/// pre-search / idle recipe-browsing surfaces (the recipe picker, the search tab's
/// empty state). With `onSelect` the cards pick; without, they open the recipe.
struct RecommendedForYouShelf: View {
    @Environment(FoodStore.self) private var store
    var onSelect: ((Recipe) -> Void)? = nil

    var body: some View {
        if !store.recommendedRecipes.isEmpty {
            ProGate {
                if let onSelect {
                    RecipeShelf("Recommended for you", recipes: store.recommendedRecipes, onSelect: onSelect)
                } else {
                    RecipeShelf("Recommended for you", recipes: store.recommendedRecipes) {
                        RecipeDetailView(recipe: $0)
                    }
                }
            }
        }
    }
}
