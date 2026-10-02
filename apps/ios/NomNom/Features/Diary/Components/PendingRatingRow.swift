import SwiftUI

/// A meal somebody else cooked that waits for the viewer's rating ("Nom Nom iOS"
/// canvas): a navigating ListRow with PhotoCard `xs`, the dish name and "{cook} cooked
/// · {date}". Rating happens on the meal screen; declining is in the row's native
/// context menu. Place it in a `Card(layout: .list)`.
struct PendingRatingRow: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store

    private var meta: String {
        let cook = store.label(for: .account(meal.createdBy)).name
        let date = meal.eatenOn.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        return cook.isEmpty ? date : "\(cook) cooked \u{00B7} \(date)"
    }

    var body: some View {
        NavigationLink {
            MealDetailView(mealID: meal.id)
        } label: {
            ListRow(
                store.dishName(forMeal: meal),
                meta: meta,
                leading: .photo(.meal(meal)),
                chevron: true
            )
        }
        .buttonStyle(ListRowButtonStyle())
        .contextMenu {
            Button("Decline", systemImage: "xmark", role: .destructive, action: decline)
        }
    }

    private func decline() {
        guard let invite = store.invites(forMeal: meal.id).first(where: { $0.inviteeID == store.userID }) else { return }
        Task { await store.decline(invite: invite) }
    }
}
