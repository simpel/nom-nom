import SwiftUI

/// Section showcasing recipes created by a user, showing image and name.
struct ProfileCreatedRecipesSection: View {
    let recipes: [Recipe]

    var body: some View {
        SectionCard("Created Recipes (\(recipes.count))") {
            if recipes.isEmpty {
                Text("No recipes created yet.")
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(recipes.enumerated()), id: \.element.id) { index, recipe in
                        NavigationLink {
                            RecipeDetailView(recipe: recipe)
                        } label: {
                            HStack(spacing: 12) {
                                recipeThumbnail(for: recipe)

                                Text(recipe.name)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(DS.Color.textPrimary)
                                    .lineLimit(1)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(DS.Color.textTertiary)
                            }
                            .padding(.vertical, 3)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < recipes.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func recipeThumbnail(for recipe: Recipe) -> some View {
        if let primaryPhoto = recipe.photoPath {
            RemoteMealPhoto(
                path: primaryPhoto,
                cornerRadius: AppRadius.photo,
                bucket: SupabaseConfig.photoBucket
            )
            .frame(width: 46, height: 46)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                    .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
            )
        } else if let cuisine = recipe.cuisine,
                  let cuisineAsset = Cuisine.assetImageName(for: cuisine) {
            Image(cuisineAsset)
                .resizable()
                .scaledToFill()
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                        .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                )
        } else {
            Rectangle()
                .fill(DS.Color.sunken)
                .frame(width: 46, height: 46)
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
        ProfileCreatedRecipesSection(recipes: store.recipes)
            .padding()
    }
}
