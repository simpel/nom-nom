import SwiftUI

/// "What they're eating" ("Nom Nom iOS" canvas): the party's five latest meals as
/// MealRows (photo, dish, date, score) in a list Card, then "See all N meals", which
/// switches to the Meals tab with this party selected. Empty, an EmptyState `card`.
struct PartyMealsSection: View {
    let party: Party

    @Environment(FoodStore.self) private var store
    @Environment(AppNavigator.self) private var navigator
    @Environment(\.dismiss) private var dismiss

    private static let previewCount = 5

    private var partyMeals: [Meal] {
        store.meals(forParty: party.id).sorted { $0.eatenOn > $1.eatenOn }
    }

    var body: some View {
        let meals = partyMeals
        if meals.isEmpty {
            DSSection("What they\u{2019}re eating") {
                EmptyState("No meals yet", message: "Meals served to this party will show up here.")
            }
        } else {
            DSSection("What they\u{2019}re eating", trailing: meals.count == 1 ? "1 meal" : "\(meals.count) meals") {
                Card(layout: .list) {
                    ForEach(meals.prefix(Self.previewCount)) { meal in
                        NavigationLink {
                            MealDetailView(mealID: meal.id)
                        } label: {
                            MealRow(meal: meal, metaStyle: .date)
                        }
                        .buttonStyle(ListRowButtonStyle())
                    }
                    if meals.count > Self.previewCount, store.isMember(of: party.id) {
                        ListRow("See all \(meals.count) meals", size: .sm, action: seeAll)
                    }
                }
            }
        }
    }

    /// The Meals tab lists the selected party's meals, so select this one and go there.
    private func seeAll() {
        store.currentParty = party
        navigator.tab = .meals
        dismiss()
    }
}
