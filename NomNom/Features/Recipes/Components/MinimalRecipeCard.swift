import SwiftUI

/// Minimalist recipe card displaying strictly 1:1 image, category caption, and title.
struct MinimalRecipeCard: View {
    let recipe: Recipe

    @Environment(FoodStore.self) private var store

    private var categoryDisplayName: String {
        if let cuisineName = Cuisine.formatDisplayName(recipe.cuisine) {
            return cuisineName.uppercased()
        }
        if let firstTag = recipe.tags.first {
            return firstTag.uppercased()
        }
        return "RECIPE"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 1:1 Square Photo with Global Recipe Image Fallback
            ZStack {
                RecipeImageView(recipe: recipe, cornerRadius: AppRadius.photo)

                if store.isFavorite(recipe: recipe) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(.black.opacity(0.45), in: Circle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(6)
                }
            }
            .aspectRatio(1, contentMode: .fill)
            .frame(minWidth: 0, maxWidth: .infinity)

            // Category & Title Labels (Fixed height for uniform card alignment)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(categoryDisplayName)
                        .font(.caption2.weight(.medium))
                        .tracking(0.4)
                        .foregroundStyle(DS.Color.accentText)

                    if recipe.ownerID != store.userID, let creator = store.profiles[recipe.ownerID]?.shortName {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(DS.Color.textTertiary)
                        Text("by \(creator)")
                            .font(.caption2)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
                .lineLimit(1)

                Text(recipe.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(height: 58, alignment: .topLeading)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                Task { await store.toggleFavorite(recipe: recipe) }
            } label: {
                Label(
                    store.isFavorite(recipe: recipe) ? "Remove from Favourites" : "Add to Favourites",
                    systemImage: store.isFavorite(recipe: recipe) ? "heart.slash" : "heart"
                )
            }
        }
    }
}
