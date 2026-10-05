import SwiftUI

/// The top of the Meals tab: a centred tab-root ScreenHeader naming the current party
/// ("Meals at The Friday Feast Club"), one sentence and "Log a meal".
struct MealsHeader: View {
    let onLogMeal: () -> Void

    @Environment(FoodStore.self) private var store

    /// The list is the current party's meals, so the title says whose.
    private var title: String {
        store.currentParty.map { "Meals at \($0.name)" } ?? "Your meals"
    }

    var body: some View {
        ScreenHeader(
            title,
            summary: "What you\u{2019}ve cooked and what\u{2019}s left to rate.",
            role: .tabRoot,
            actions: [ScreenHeaderAction(title: "Log a meal", action: onLogMeal)]
        )
    }
}
