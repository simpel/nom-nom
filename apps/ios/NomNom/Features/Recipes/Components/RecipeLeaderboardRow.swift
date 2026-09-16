import SwiftUI

/// Clean, dedicated row component for the Global Leaderboard displaying rank, photo,
/// recipe name & metadata, reaction-colored score, and disclosure chevron.
struct RecipeLeaderboardRow: View {
    let rank: Int
    let recipe: Recipe
    let score: Double
    let reaction: Reaction
    var isHighlighted: Bool = false

    @Environment(FoodStore.self) private var store

    private var photos: [String] {
        store.photos(for: recipe)
    }

    private var servings: [Meal] {
        store.servings(of: recipe.id)
    }

    private var cuisineName: String? {
        Cuisine.formatDisplayName(recipe.cuisine)
    }

    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.sm) {
            rankView

            thumbnailView

            recipeDetails

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(DS.Color.textTertiary)
        }
        .padding(.vertical, DS.Spacing.sm)
        .padding(.horizontal, 10)
        .background {
            if isHighlighted {
                RoundedRectangle(cornerRadius: AppRadius.card - 4, style: .continuous)
                    .fill(DS.Color.sunken)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.card - 4, style: .continuous)
                            .strokeBorder(DS.Color.line, lineWidth: 1)
                    )
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: - Subviews

    @ViewBuilder
    private var rankView: some View {
        Text("\(rank)")
            .font(rankFont)
            .foregroundStyle(rankColor)
            .monospacedDigit()
            .frame(width: 24, alignment: .leading)
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if !photos.isEmpty {
            MiniPhotoArcDeck(
                photoPaths: photos,
                cardWidth: 38,
                cardHeight: 48,
                cornerRadius: AppRadius.photo
            )
        } else if let cuisineImage = Cuisine.assetImageName(for: recipe.cuisine) {
            Image(cuisineImage)
                .resizable()
                .scaledToFill()
                .frame(width: 38, height: 48)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                        .strokeBorder(DS.Color.line, lineWidth: 0.5)
                )
        } else {
            RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                .fill(DS.Color.sunken)
                .frame(width: 38, height: 48)
                .overlay {
                    Image(systemName: "fork.knife")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textTertiary)
                }
        }
    }

    @ViewBuilder
    private var recipeDetails: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(recipe.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if store.isFavorite(recipe: recipe) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.accent)
                }
            }

            HStack(spacing: 6) {
                if let cuisineName {
                    Text(cuisineName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(DS.Color.accentText)
                }

                if let effort = recipe.effort {
                    if cuisineName != nil {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                    Text(effort.label)
                        .font(.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }

                if servings.count > 0 {
                    if cuisineName != nil || recipe.effort != nil {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                    Text("\(servings.count)× cooked")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            .lineLimit(1)
        }
    }

    // MARK: - Rank Styling

    private var rankFont: Font {
        switch rank {
        case 1:
            return Font.newsreader(.title3, weight: .bold)
        case 2, 3:
            return Font.newsreader(.headline, weight: .semibold)
        default:
            return Font.inter(.subheadline, weight: .medium)
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1, 2, 3:
            return DS.Color.textPrimary
        default:
            return DS.Color.textTertiary
        }
    }
}
