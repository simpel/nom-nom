import SwiftUI

/// Section displaying meals waiting for the current user's rating.
struct MealsToRateSection: View {
    @Environment(FoodStore.self) private var store

    var body: some View {
        if !store.awaitingMyRating.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("WAITING FOR YOUR RATING")
                    .font(.caption.weight(.semibold))
                    .tracking(0.5)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    ForEach(Array(store.awaitingMyRating.enumerated()), id: \.element.id) { index, meal in
                        PendingRatingCard(meal: meal)
                            .padding(14)

                        if index < store.awaitingMyRating.count - 1 {
                            Divider()
                                .overlay(DS.Color.line.opacity(0.3))
                                .padding(.leading, 14)
                        }
                    }
                }
                .background(DS.Color.panel)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                )
            }
        }
    }
}
