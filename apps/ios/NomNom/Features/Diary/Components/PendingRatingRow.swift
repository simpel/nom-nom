import SwiftUI

/// A meal waiting for the viewer's rating ("Nom Nom iOS" canvas): a split ListRow with
/// PhotoCard `xs`, the dish name and "{cook} cooked \u{00B7} {date}" (just the date for
/// the viewer's own meals), and a `primary soft sm` "Rate" button. The row opens the meal page and Rate
/// opens the rate flow in a sheet; declining an invite is in the row's native context menu. Place it in a
/// `Card(layout: .list)`.
struct PendingRatingRow: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store
    @State private var showDetail = false
    @State private var showRating = false

    private var isOwn: Bool { meal.createdBy == store.userID }

    private var meta: String {
        let date = meal.eatenOn.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        guard !isOwn else { return date }
        guard let createdBy = meal.createdBy else { return date }
        let cook = store.label(for: .account(createdBy)).name
        return cook.isEmpty ? date : "\(cook) cooked \u{00B7} \(date)"
    }

    var body: some View {
        ListRow(
            store.dishName(forMeal: meal),
            meta: meta,
            leading: .photo(.meal(meal)),
            trailing: .button(AppButton("Rate", appearance: .soft, size: .sm) { showRating = true }),
            chevron: false,
            action: { showDetail = true }
        )
        .contextMenu {
            if !isOwn {
                Button("Decline", systemImage: "xmark", role: .destructive, action: decline)
            }
        }
        .navigationDestination(isPresented: $showDetail) {
            MealDetailView(mealID: meal.id)
        }
        .sheet(isPresented: $showRating) { RateMealSheet(mealID: meal.id) }
    }

    private func decline() {
        guard let invite = store.invites(forMeal: meal.id).first(where: { $0.inviteeID == store.userID }) else { return }
        Task { await store.decline(invite: invite) }
    }
}
