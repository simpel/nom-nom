import SwiftUI

/// Section displaying meals waiting for the current user's rating: one
/// PendingRatingCard per meal in a list Card under a "Waiting for your rating" header.
struct MealsToRateSection: View {
    @Environment(FoodStore.self) private var store

    var body: some View {
        if !store.awaitingMyRating.isEmpty {
            DSSection("Waiting for your rating", trailing: "\(store.awaitingMyRating.count)") {
                Card(layout: .list) {
                    ForEach(store.awaitingMyRating) { meal in
                        PendingRatingCard(meal: meal)
                    }
                }
            }
        }
    }
}
