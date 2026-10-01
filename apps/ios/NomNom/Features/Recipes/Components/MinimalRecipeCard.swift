import SwiftUI

/// Minimalist recipe card displaying strictly 1:1 image, category caption, and title.
/// Powered by the centralized `RecipeCard` component.
struct MinimalRecipeCard: View {
    let recipe: Recipe

    var body: some View {
        RecipeCard(recipe: recipe)
    }
}

#Preview {
    NomNomPreview { store in
        if let recipe = store.recipes.first {
            MinimalRecipeCard(recipe: recipe)
                .frame(width: 156)
                .padding()
        }
    }
}
