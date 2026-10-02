import SwiftUI

/// RecipeDetailView's DetailHeader (the README's Recipe recipe): cuisine eyebrow, the
/// dish as title, "Last cooked 28 Aug 2026 · 6 times" (or "Never cooked"), time /
/// method / rotation fact Badges and the one solid action, "Use in a meal".
struct RecipeDetailHeader: View {
    let recipe: Recipe
    /// Servings, newest first.
    let history: [Meal]
    let onUseInMeal: () -> Void

    @Environment(FoodStore.self) private var store

    private var meta: String {
        guard let last = history.first?.eatenOn else { return "Never cooked" }
        let times = history.count == 1 ? "1 time" : "\(history.count) times"
        return "Last cooked \(last.formatted(.dateTime.day().month(.abbreviated).year())) \u{00B7} \(times)"
    }

    private var facts: [Badge] {
        var badges: [Badge] = []
        if let effort = recipe.effort {
            badges.append(Badge(effort.label, icon: "clock", variant: .secondary, size: .sm))
        }
        if let method = store.cookingMethod(for: recipe) {
            badges.append(Badge(method.name, variant: .secondary, size: .sm))
        }
        if let rotation = store.averageRotation(forDish: recipe.id) {
            badges.append(.rotation(rotation))
        }
        return badges
    }

    var body: some View {
        DetailHeader(
            title: recipe.name,
            eyebrow: Cuisine.formatDisplayName(recipe.cuisine),
            meta: meta,
            facts: facts,
            actions: [DetailHeaderAction(title: "Use in a meal", icon: "plus", action: onUseInMeal)]
        )
    }
}
