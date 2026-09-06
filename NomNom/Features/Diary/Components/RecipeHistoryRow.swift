import SwiftUI

/// Simplified row in the recipe cooked history list showing:
/// - Meal photo / cuisine placeholder
/// - Date cooked (primary)
/// - Dinner party / chef (secondary)
/// - Average rating pill (if available)
struct RecipeHistoryRow: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store

    private var partyNames: String {
        store.parties(forMeal: meal.id).map(\.name).joined(separator: ", ")
    }

    private var subtitle: String {
        if !partyNames.isEmpty {
            return partyNames
        }
        if meal.createdBy == store.userID {
            return "Cooked by you"
        }
        return "Cooked by \(store.label(for: .account(meal.createdBy)).name)"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            thumbnailView

            VStack(alignment: .leading, spacing: 3) {
                Text(meal.eatenOn, format: .dateTime.day().month(.abbreviated).year())
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DS.Color.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let score = store.averageScore(forMeal: meal.id),
               let reaction = store.averageReaction(forMeal: meal.id) {
                ScoreBadge(score: score, reaction: reaction, format: .scoreOnly, size: .sm)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let primaryPhoto = meal.photoPaths.first {
            RemoteMealPhoto(
                path: primaryPhoto,
                cornerRadius: AppRadius.photo,
                bucket: SupabaseConfig.photoBucket
            )
            .frame(width: 44, height: 44)
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
                .frame(width: 44, height: 44)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                        .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                )
        } else {
            RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                .fill(DS.Color.sunken)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                        .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                )
                .overlay {
                    Image(systemName: "fork.knife")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                }
        }
    }
}
