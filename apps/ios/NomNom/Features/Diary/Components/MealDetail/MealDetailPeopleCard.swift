import SwiftUI

/// Who cooked the meal and which dinner party it belongs to, as ListRows that open
/// the cook's profile and the party.
struct MealDetailPeopleCard: View {
    let meal: Meal
    let onOpenParty: (Party) -> Void

    @Environment(FoodStore.self) private var store

    private var cookName: String {
        meal.createdBy == store.userID ? "You" : store.label(for: .account(meal.createdBy)).name
    }

    var body: some View {
        let parties = store.parties(forMeal: meal.id)

        Card(layout: .list) {
            NavigationLink {
                PersonDetailView(raterRef: .account(meal.createdBy))
            } label: {
                ListRow(
                    "Cooked by",
                    value: cookName,
                    leading: .avatar(Avatar(
                        name: cookName,
                        photoPath: store.profiles[meal.createdBy]?.photoPath,
                        size: .sm,
                        decorative: true
                    )),
                    chevron: true
                )
            }
            .buttonStyle(ListRowButtonStyle())

            if let party = parties.first {
                ListRow("Dinner party", value: parties.map(\.name).joined(separator: ", ")) {
                    onOpenParty(party)
                }
            }
        }
    }
}
