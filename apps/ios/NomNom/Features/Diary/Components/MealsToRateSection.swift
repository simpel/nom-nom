import SwiftUI

/// Section displaying meals waiting for the current user's rating: one
/// PendingRatingRow per meal in a list Card under a "Waiting for your rating" header
/// with the count in `primary-text`.
struct MealsToRateSection: View {
    @Environment(FoodStore.self) private var store

    var body: some View {
        if !store.awaitingMyRating.isEmpty {
            DSSection("Waiting for your rating", trailing: "\(store.awaitingMyRating.count)", trailingTone: .primary) {
                Card(layout: .list) {
                    ForEach(store.awaitingMyRating) { meal in
                        PendingRatingRow(meal: meal)
                    }
                }
            }
        }
    }
}
