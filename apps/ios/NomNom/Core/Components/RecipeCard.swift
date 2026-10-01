import SwiftUI

/// Generic, modular recipe card used across shelves, grids, carousels, and insight views.
/// Adheres to global recipe card visual language: 1:1 image, category tag, title, and optional footer content.
struct RecipeCard<Footer: View>: View {
    let recipe: Recipe
    var subtitle: String?
    var footer: Footer

    @Environment(FoodStore.self) private var store

    init(
        recipe: Recipe,
        subtitle: String? = nil,
        @ViewBuilder footer: () -> Footer
    ) {
        self.recipe = recipe
        self.subtitle = subtitle
        self.footer = footer()
    }

    init(
        recipe: Recipe,
        subtitle: String? = nil
    ) where Footer == EmptyView {
        self.recipe = recipe
        self.subtitle = subtitle
        self.footer = EmptyView()
    }

    private var categoryDisplayName: String {
        if let subtitle, !subtitle.isEmpty {
            return subtitle.uppercased()
        }
        if let cuisineName = Cuisine.formatDisplayName(recipe.cuisine) {
            return cuisineName.uppercased()
        }
        if let kind = store.dishKind(for: recipe) {
            return kind.name.uppercased()
        }
        if let method = store.cookingMethod(for: recipe) {
            return method.name.uppercased()
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
            .aspectRatio(1, contentMode: .fit)
            .frame(minWidth: 0, maxWidth: .infinity)

            // Category & Title Labels (Fixed height for uniform card alignment across rows)
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

                if !(Footer.self == EmptyView.self) {
                    footer
                        .padding(.top, 2)
                }
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

            if recipe.ownerID == store.userID {
                Button(role: .destructive) {
                    Task { await store.delete(recipe: recipe) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let recipe = store.recipes.first {
            RecipeCard(recipe: recipe) {
                Text("Sample Footer")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .frame(width: 160)
            .padding()
        }
    }
}
