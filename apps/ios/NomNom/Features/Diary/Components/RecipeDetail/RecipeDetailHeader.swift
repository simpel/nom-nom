import SwiftUI

/// RecipeDetailView's DetailHeader (the README's Recipe recipe): cuisine eyebrow, the
/// dish as title, "Last cooked 28 Aug 2026 · 6 times" (or "Never cooked"), time and
/// method as facts, the rotation goal as a status Badge and the one solid action,
/// "Use in a meal".
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

    /// README Recipe recipe: "facts (time, method)".
    private var facts: [String] {
        [recipe.effort?.label, store.cookingMethod(for: recipe)?.name].compactMap { $0 }
    }

    /// README Recipe recipe: "badges (the rotation goal, when it is a status)".
    private var badges: [Badge] {
        store.averageRotation(forDish: recipe.id).map { [.rotation($0)] } ?? []
    }

    var body: some View {
        DetailHeader(
            title: recipe.name,
            eyebrow: Cuisine.formatDisplayName(recipe.cuisine),
            meta: meta,
            facts: facts,
            badges: badges,
            actions: [DetailHeaderAction(title: "Use in a meal", icon: "plus", action: onUseInMeal)]
        )
    }
}
