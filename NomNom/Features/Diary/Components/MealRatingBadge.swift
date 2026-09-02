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
        let reaction: Reaction = {
            if ratings.count == 1, let single = ratings.first?.reaction {
                return single
            }
            let score = store.averageScore(forMeal: meal.id) ?? 0.5
            if score >= 0.8 { return .amazing }
            if score >= 0.6 { return .good }
            if score >= 0.4 { return .meh }
            if score >= 0.2 { return .bad }
            return .inedible
        }()

        let label: String = {
            if ratings.count == 1 {
                return ratings.first?.reaction.shortLabel ?? reaction.shortLabel
            }
            let score = store.averageScore(forMeal: meal.id) ?? 0.5
            return "\(Int((score * 100).rounded()))%"
        }()

        HStack(spacing: 4) {
            Image(systemName: reaction.systemImage)
                .font(.system(size: 10, weight: .semibold))
            Text(label)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(reaction.text)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(reaction.fill.opacity(0.14))
        }
        .overlay {
            Capsule()
                .strokeBorder(reaction.fill.opacity(0.28), lineWidth: 1)
        }
        .accessibilityLabel("\(reaction.name): \(label)")
    }
}
