import SwiftUI

/// RecipeDetailView's DetailHeader ("Nom Nom iOS" canvas): cuisine eyebrow, the dish
/// as title, "Last cooked 1 Oct 2026 · 6 times · by Joel" (or "Never cooked"), time,
/// method and servings as facts, the rotation goal as a status Badge, then "Start
/// cooking" (solid, when there are steps) and "Use in a meal" (secondary soft).
struct RecipeDetailHeader: View {
    let recipe: Recipe
    /// Servings, newest first.
    let history: [Meal]
    let onStartCooking: () -> Void
    let onUseInMeal: () -> Void

    @Environment(FoodStore.self) private var store

    private var creator: String {
        recipe.ownerID == store.userID ? "you" : store.firstName(for: .account(recipe.ownerID))
    }

    private var meta: String {
        guard let last = history.first?.eatenOn else { return "Never cooked \u{00B7} by \(creator)" }
        let times = history.count == 1 ? "1 time" : "\(history.count) times"
        return "Last cooked \(last.formatted(.dateTime.day().month(.abbreviated).year())) \u{00B7} \(times) \u{00B7} by \(creator)"
    }

    /// Time, method and servings.
    private var facts: [String] {
        [recipe.effort?.label, store.cookingMethod(for: recipe)?.name, recipe.serves.map { "Serves \($0)" }]
            .compactMap { $0 }
    }

    private var actions: [DetailHeaderAction] {
        let use = DetailHeaderAction(title: "Use in a meal", icon: "plus", action: onUseInMeal)
        guard !recipe.instructions.isEmpty else { return [use] }
        return [
            DetailHeaderAction(title: "Start cooking", icon: "flame", action: onStartCooking),
            DetailHeaderAction(title: use.title, icon: use.icon, variant: .secondary, appearance: .soft, action: onUseInMeal),
        ]
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
            actions: actions
        )
    }
}
