import SwiftUI

/// Composable container for displaying a recipe's structured ingredients, step-by-step instructions, and photo pages.
struct RecipeInstructionsCard: View {
    let recipe: Recipe

    var body: some View {
        if recipe.hasInstructions {
            VStack(spacing: 16) {
                if !recipe.ingredients.isEmpty {
                    RecipeIngredientsCard(ingredients: recipe.ingredients)
                }

                if !recipe.instructions.isEmpty {
                    RecipeStepsCard(instructions: recipe.instructions)
                }

                if !recipe.recipePhotoPaths.isEmpty {
                    RecipePhotosCard(recipe: recipe)
                }
            }
        }
    }
}
