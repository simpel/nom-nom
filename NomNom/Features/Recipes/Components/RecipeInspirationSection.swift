import SwiftUI

/// Section containing recipe discovery content: favorite recipes shelf,
/// popular recipes shelf, and cuisine categories grid.
struct RecipeInspirationSection: View {
    @Environment(FoodStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sectionLarge) {
            if !store.favoriteRecipes.isEmpty {
                RecipeHorizontalShelf(title: "Favourites", recipes: store.favoriteRecipes)
            }

            if !store.popularRecipes.isEmpty {
                RecipeHorizontalShelf(title: "Popular Recipes", recipes: store.popularRecipes)
            }

            RecipeCategoryGridSection()
        }
    }
}

#Preview {
    NomNomPreview {
        NavigationStack {
            ScrollView {
                RecipeInspirationSection()
            }
        }
    }
}
