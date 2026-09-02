import SwiftUI

/// One row in the diary log list, inspired by the clean typography of Apple Notes.
struct MealRow: View {
    let meal: Meal
    var raterRef: RaterRef? = nil

    @Environment(FoodStore.self) private var store

    private var ratingSummaryText: String? {
        if let raterRef, let rating = store.rating(for: raterRef, on: meal.id) {
            return rating.reaction.shortLabel
        }
        let ratings = store.ratings(forMeal: meal.id)
        if ratings.count == 1 {
            return ratings.first?.reaction.shortLabel
        } else if ratings.count > 1 {
            return store.averageReaction(forMeal: meal.id)?.shortLabel
        }
        return nil
    }

    private var tasteAndRotationSummary: String? {
        var parts: [String] = []
        if let rating = ratingSummaryText {
            parts.append(rating)
        }
        if let rotation = store.averageRotation(forMeal: meal.id) {
            parts.append(rotation.title)
        }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " - ")
    }

    var body: some View {
        HStack(spacing: 12) {
            MiniPhotoArcDeck(
                photoPaths: meal.photoPaths,
                cardWidth: 42,
                cardHeight: 54,
                cornerRadius: AppRadius.photo
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(store.dishName(forMeal: meal))
                    .font(.inter(.body, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(meal.eatenOn, format: .dateTime.day().month(.abbreviated))
                    .font(.inter(.subheadline))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let summary = tasteAndRotationSummary {
                    Text(summary)
                        .font(.inter(.caption))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 3)
    }
}

