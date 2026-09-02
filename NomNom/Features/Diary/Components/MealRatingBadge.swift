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
        HStack(spacing: 3) {
            Image(systemName: rotation.systemImage)
                .font(.system(size: 10, weight: .semibold))
            Text(rotation.title)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(rotation.tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(rotation.tint.opacity(0.12))
        }
        .overlay {
            Capsule()
                .strokeBorder(rotation.tint.opacity(0.24), lineWidth: 1)
        }
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
        let score = store.averageScore(forMeal: meal.id) ?? 0.5
        let mood: (label: String, tint: Color) = {
            if score >= 0.75 {
                let label = ratings.count == 1 ? (ratings.first?.reaction.shortLabel ?? "Loved") : "\(Int((score * 100).rounded()))%"
                return (label, .green)
            } else if score >= 0.35 {
                let label = ratings.count == 1 ? (ratings.first?.reaction.shortLabel ?? "Ok") : "\(Int((score * 100).rounded()))%"
                return (label, .orange)
            } else {
                let label = ratings.count == 1 ? (ratings.first?.reaction.shortLabel ?? "Nope") : "\(Int((score * 100).rounded()))%"
                return (label, .red)
            }
        }()

        Text(mood.label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(mood.tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(mood.tint.opacity(0.14))
            }
            .overlay {
                Capsule()
                    .strokeBorder(mood.tint.opacity(0.28), lineWidth: 1)
            }
    }
}
