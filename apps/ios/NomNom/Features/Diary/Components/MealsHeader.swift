import SwiftUI

/// The top of the Meals tab ("Nom Nom iOS" canvas): a DetailHeader with the party as
/// meta, "Meals" as the title, "{party} has logged 16 meals, 4 of them this week." and
/// one solid "Log a meal" action.
struct MealsHeader: View {
    let meals: [Meal]
    let onLogMeal: () -> Void

    @Environment(FoodStore.self) private var store

    private var who: String { store.currentParty?.name ?? "You" }

    private var summary: String? {
        guard !meals.isEmpty else { return nil }
        let start = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        let thisWeek = meals.filter { $0.eatenOn >= start }.count
        let logged = "\(who) \(store.currentParty == nil ? "have" : "has") logged \(meals.count == 1 ? "1 meal" : "\(meals.count) meals")"
        return thisWeek > 0 ? "\(logged), \(thisWeek) of them this week." : "\(logged)."
    }

    var body: some View {
        DetailHeader(
            title: "Meals",
            meta: store.currentParty?.name ?? "Just me",
            summary: summary,
            actions: [DetailHeaderAction(title: "Log a meal", icon: "plus", action: onLogMeal)]
        )
    }
}
