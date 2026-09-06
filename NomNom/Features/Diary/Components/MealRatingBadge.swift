import SwiftUI

/// Centered badge displaying the overall rating verdict or summary score for a meal.
struct MealRatingBadge: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store

    var body: some View {
        HStack(spacing: 6) {
            if let rotation = store.averageRotation(forMeal: meal.id) {
                rotationBadge(rotation)
            }

            let ratings = store.ratings(forMeal: meal.id)
            if ratings.isEmpty {
                unratedBadge
            } else {
                ratedBadge(ratings: ratings)
            }
        }
    }

    @ViewBuilder
    private func rotationBadge(_ rotation: RotationGoal) -> some View {
        RotationPill(goal: rotation)
    }

    @ViewBuilder
    private var unratedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.dashed")
                .font(.system(size: 10, weight: .medium))
            Text("Unrated")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(.secondary.opacity(0.7))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule().fill(Color(uiColor: .tertiarySystemFill))
        }
    }

    @ViewBuilder
    private func ratedBadge(ratings: [MealRating]) -> some View {
        if ratings.count == 1, let single = ratings.first?.reaction {
            ScoreBadge(reaction: single, format: .verdictOnly, size: .sm)
        } else if let score = store.averageScore(forMeal: meal.id) {
            ScoreBadge(score: score, format: .scoreOnly, size: .sm)
        }
    }
}
