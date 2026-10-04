import SwiftUI

/// RecipeDetailView's ScreenHeader: the cuisine as the eyebrow, the dish as the title,
/// then "Start cooking" (solid, when there are steps) and "Use in a meal" (secondary soft).
/// Time, method, servings and the rotation goal are RecipeDetailFacts, below the photos.
struct RecipeDetailHeader: View {
    let recipe: Recipe
    let onStartCooking: () -> Void
    let onUseInMeal: () -> Void

    private var actions: [ScreenHeaderAction] {
        guard !recipe.instructions.isEmpty else {
            return [ScreenHeaderAction(title: "Use in a meal", action: onUseInMeal)]
        }
        return [
            ScreenHeaderAction(title: "Start cooking", action: onStartCooking),
            ScreenHeaderAction(title: "Use in a meal", variant: .secondary, appearance: .soft, action: onUseInMeal),
        ]
    }

    var body: some View {
        ScreenHeader(
            recipe.name,
            eyebrow: Cuisine.formatDisplayName(recipe.cuisine),
            actions: actions
        )
    }
}
