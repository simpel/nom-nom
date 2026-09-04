import SwiftUI

/// Section listing meal history on a user profile: shows image, name, rating, and date.
struct ProfileMealHistorySection: View {
    let meals: [Meal]
    let raterRef: RaterRef

    @Environment(FoodStore.self) private var store

    var body: some View {
        SectionCard("Meal History (\(meals.count))") {
            if meals.isEmpty {
                Text("No meals logged yet.")
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                        NavigationLink {
                            MealDetailView(mealID: meal.id)
                        } label: {
                            mealRow(for: meal)
                        }
                        .buttonStyle(.plain)

                        if index < meals.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func mealRow(for meal: Meal) -> some View {
        HStack(alignment: .center, spacing: 12) {
            mealThumbnail(for: meal)

            VStack(alignment: .leading, spacing: 4) {
                Text(store.dishName(forMeal: meal))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(meal.eatenOn, format: .dateTime.day().month(.abbreviated).year())
                        .font(.caption)
                        .foregroundStyle(DS.Color.textSecondary)

                    if let rating = userRating(for: meal) {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(DS.Color.textTertiary)

                        Text(rating.shortLabel)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(rating.text)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(rating.fill.opacity(0.14)))
                            .overlay(
                                Capsule().strokeBorder(rating.fill.opacity(0.28), lineWidth: 0.5)
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(DS.Color.textTertiary)
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }

    private func userRating(for meal: Meal) -> Reaction? {
        if let direct = store.rating(for: raterRef, on: meal.id) {
            return direct.reaction
        }
        return store.averageReaction(forMeal: meal.id)
    }

    @ViewBuilder
    private func mealThumbnail(for meal: Meal) -> some View {
        if meal.photoPaths.count > 1 {
            MiniPhotoArcDeck(
                photoPaths: meal.photoPaths,
                cardWidth: 42,
                cardHeight: 52
            )
        } else if let primaryPhoto = meal.photoPaths.first {
            RemoteMealPhoto(
                path: primaryPhoto,
                cornerRadius: AppRadius.photo,
                bucket: SupabaseConfig.photoBucket
            )
            .frame(width: 44, height: 54)
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
                .frame(width: 44, height: 54)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                        .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                )
        } else {
            Rectangle()
                .fill(DS.Color.sunken)
                .frame(width: 44, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
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

#Preview {
    NomNomPreview { store in
        ProfileMealHistorySection(
            meals: store.meals,
            raterRef: .account(store.userID)
        )
        .padding()
    }
}
