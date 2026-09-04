import SwiftUI

/// Horizontal scroll shelf displaying curated popular recipes in minimal cards.
struct PopularRecipesShelf: View {
    let recipes: [Recipe]
    var onSelect: ((Recipe) -> Void)? = nil

    var body: some View {
        RecipeHorizontalShelf(title: "Popular Recipes", recipes: recipes, onSelect: onSelect)
    }
}

#Preview {
    NomNomPreview {
        NavigationStack {
            PopularRecipesShelf(recipes: [])
        }
    }
}
