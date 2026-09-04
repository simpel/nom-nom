import SwiftUI

/// One row in the diary log list, inspired by the clean typography of Apple Notes.
struct MealRow: View {
    let meal: Meal
    var raterRef: RaterRef? = nil
    var isMinimal: Bool = false

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

    private var partyNames: String {
        store.parties(forMeal: meal.id).map(\.name).joined(separator: ", ")
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            thumbnailView

            VStack(alignment: .leading, spacing: isMinimal ? 4 : 3) {
                Text(store.dishName(forMeal: meal))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)

                if isMinimal {
                    if !partyNames.isEmpty {
                        Text(partyNames)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(DS.Color.accentText)
                            .lineLimit(1)
                    }
                } else {
                    HStack(spacing: 6) {
                        if !partyNames.isEmpty {
                            Text(partyNames)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(DS.Color.accentText)
                                .lineLimit(1)
                        }

                        if let summary = ratingSummaryText {
                            if !partyNames.isEmpty {
                                Text("•")
                                    .font(.caption2)
                                    .foregroundStyle(DS.Color.textTertiary)
                            }
                            Text(summary)
                                .font(.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                        }

                        if let effort = meal.effort ?? store.dish(meal.dishID)?.effort {
                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(DS.Color.textTertiary)
                            Text(effort.label)
                                .font(.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                    }

                    if !meal.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(meal.notes)
                            .font(.caption2)
                            .foregroundStyle(DS.Color.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !isMinimal {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if meal.photoPaths.count > 1 {
            MiniPhotoArcDeck(
                photoPaths: meal.photoPaths,
                cardWidth: 42,
                cardHeight: 54
            )
        } else if let primaryPhoto = meal.photoPaths.first {
            RemoteMealPhoto(
                path: primaryPhoto,
                cornerRadius: AppRadius.photo,
                bucket: SupabaseConfig.photoBucket
            )
            .frame(width: 46, height: 58)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                    .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
            )
        } else if let cuisine = store.dish(meal.dishID)?.cuisine,
                  let cuisineAsset = Cuisine.assetImageName(for: cuisine) {
            Image(cuisineAsset)
                .resizable()
                .scaledToFill()
                .frame(width: 46, height: 58)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                        .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                )
        } else {
            Rectangle()
                .fill(DS.Color.sunken)
                .frame(width: 46, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                        .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                )
                .overlay {
                    Image(systemName: "fork.knife")
                        .font(.subheadline)
                        .foregroundStyle(DS.Color.textTertiary)
                }
        }
    }
}

#Preview("Minimal") {
    NomNomPreview { store in
        if let meal = store.meals.first {
            VStack(spacing: 0) {
                MealRow(meal: meal, isMinimal: true)
                    .padding(14)
            }
            .background(DS.Color.panel)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
            .padding()
        }
    }
}

#Preview("Full") {
    NomNomPreview { store in
        if let meal = store.meals.first {
            VStack(spacing: 0) {
                MealRow(meal: meal, isMinimal: false)
                    .padding(14)
            }
            .background(DS.Color.panel)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
            .padding()
        }
    }
}

