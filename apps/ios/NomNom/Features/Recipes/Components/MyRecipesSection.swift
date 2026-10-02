import SwiftUI

/// The user's own recipes as a titled two-column grid, or an EmptyState card.
struct MyRecipesSection: View {
    let recipes: [Recipe]
    var onCreateRecipe: (() -> Void)? = nil

    var body: some View {
        if recipes.isEmpty {
            EmptyState(
                "No recipes yet",
                message: "Add a recipe you cook often and it will show up here.",
                action: EmptyStateAction("Add recipe") { onCreateRecipe?() }
            )
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s5)
        } else {
            MinimalRecipeGrid(recipes: recipes, title: "My recipes")
        }
    }
}

#Preview {
    NomNomPreview {
        NavigationStack {
            ScrollView {
                MyRecipesSection(recipes: [])
            }
        }
    }
}
