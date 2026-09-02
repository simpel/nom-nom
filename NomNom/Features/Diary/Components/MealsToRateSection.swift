import SwiftUI

/// Section displaying meals waiting for the current user's rating.
struct MealsToRateSection: View {
    @Environment(FoodStore.self) private var store

    var body: some View {
        if !store.awaitingMyRating.isEmpty {
            SectionCard("Waiting for your rating") {
                VStack(spacing: 12) {
                    ForEach(store.awaitingMyRating) { meal in
                        PendingRatingCard(meal: meal)
                        if meal.id != store.awaitingMyRating.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}
