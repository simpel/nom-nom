import SwiftUI

/// Recipe discovery: the favourites and popular RecipeShelves and the cuisine
/// categories grid, inside the screen gutter.
struct RecipeInspirationSection: View {
    @Environment(FoodStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.block) {
            RecipeShelf("Favourites", recipes: store.favoriteRecipes) { RecipeDetailView(recipe: $0) }
            RecipeShelf("Popular recipes", recipes: store.popularRecipes) { RecipeDetailView(recipe: $0) }
            RecipeCategoryGridSection()
        }
        .padding(.horizontal, DS.Spacing.gutter)
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
