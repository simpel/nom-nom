import SwiftUI

/// Who cooked the meal, which dinner party it belongs to and how long it took, as
/// ListRows; the first two open the cook's profile and the party.
struct MealDetailPeopleCard: View {
    let meal: Meal
    let onOpenParty: (Party) -> Void

    @Environment(FoodStore.self) private var store

    private var cookName: String {
        guard let createdBy = meal.createdBy else { return "Unknown" }
        return createdBy == store.userID ? "You" : store.label(for: .account(createdBy)).name
    }

    var body: some View {
        let parties = store.parties(forMeal: meal.id)

        Card(layout: .list) {
            if let createdBy = meal.createdBy {
                NavigationLink {
                    PersonDetailView(raterRef: .account(createdBy))
                } label: {
                    ListRow(
                        "Cooked by",
                        value: cookName,
                        leading: .avatar(Avatar(
                            name: cookName,
                            photoPath: store.profiles[createdBy]?.photoPath,
                            size: .sm,
                            decorative: true
                        )),
                        chevron: true
                    )
                }
                .buttonStyle(ListRowButtonStyle())
            }

            if let party = parties.first {
                ListRow("Dinner party", value: parties.map(\.name).joined(separator: ", ")) {
                    onOpenParty(party)
                }
            }

            if let effort = (meal.effort ?? store.dish(meal.dishID)?.effort)?.label {
                ListRow("Cooking time", value: effort)
            }
        }
    }
}
