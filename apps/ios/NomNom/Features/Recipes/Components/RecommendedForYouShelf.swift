import SwiftUI

/// Pro-gated shelf of `SuggestionEngine`-ranked recipes, shown at the top of pre-search /
/// idle recipe-browsing surfaces (the recipe picker, the search tab's empty state).
struct RecommendedForYouShelf: View {
    @Environment(FoodStore.self) private var store
    var onSelect: ((Recipe) -> Void)? = nil

    var body: some View {
        if !store.recommendedRecipes.isEmpty {
            ProGate {
                RecipeHorizontalShelf(title: "Recommended for You", recipes: store.recommendedRecipes, onSelect: onSelect)
            }
        }
    }
}
