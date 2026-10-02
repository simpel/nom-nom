import SwiftUI

/// ProCard holding a RecipeShelf of `SuggestionEngine`-ranked recipes, shown at the top of
/// pre-search / idle recipe-browsing surfaces (the recipe picker, the search tab's
/// empty state). With `onSelect` the cards pick; without, they open the recipe.
struct RecommendedForYouShelf: View {
    @Environment(FoodStore.self) private var store
    var onSelect: ((Recipe) -> Void)? = nil

    var body: some View {
        if !store.recommendedRecipes.isEmpty {
            ProCard(
                "Recommended for you",
                teaser: "Recipes picked from what your party rates highest and what you haven\u{2019}t had for a while.",
                contentBleed: DS.Spacing.s5
            ) {
                if let onSelect {
                    RecipeShelf("", recipes: store.recommendedRecipes, bleed: DS.Spacing.s5, onSelect: onSelect)
                } else {
                    RecipeShelf("", recipes: store.recommendedRecipes, bleed: DS.Spacing.s5) {
                        RecipeDetailView(recipe: $0)
                    }
                }
            }
        }
    }
}
