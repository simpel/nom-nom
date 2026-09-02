import SwiftUI

/// Clean card row displaying a recipe's thumbnail, title, cuisine, effort, and stats.
struct RecipeRowCard: View {
    let recipe: Recipe

    @Environment(FoodStore.self) private var store

    private var photos: [String] {
        store.photos(for: recipe)
    }

    private var servings: [Meal] {
        store.servings(of: recipe.id)
    }

    private var lastEatenDate: Date? {
        servings.map(\.eatenOn).max()
    }

    private var cuisineName: String? {
        Cuisine.formatDisplayName(recipe.cuisine)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            if !photos.isEmpty {
                MiniPhotoArcDeck(
                    photoPaths: photos,
                    cardWidth: 46,
                    cardHeight: 58,
                    cornerRadius: AppRadius.photo
                )
            } else if let cuisineImage = Cuisine.assetImageName(for: recipe.cuisine) {
                Image(cuisineImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 46, height: 58)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                            .strokeBorder(DS.Color.line, lineWidth: 0.5)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(recipe.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if !recipe.isPublic && recipe.ownerID == store.userID {
                        Text("Private")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(uiColor: .tertiarySystemFill))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 8) {
                    if let cuisineName {
                        Text(cuisineName)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.tint)
                    }

                    if let effort = recipe.effort {
                        if cuisineName != nil {
                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Text(effort.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if servings.count > 0 {
                        if cuisineName != nil || recipe.effort != nil {
                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Text("\(servings.count)× cooked")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !recipe.tags.isEmpty {
                    Text(recipe.tags.joined(separator: " • "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
