import SwiftUI

/// Unified image component for recipes adhering to global display hierarchy:
/// 1. Available user/cloud image (meal photo or recipe photo)
/// 2. Category / cuisine illustration asset (if no photo is available)
/// 3. The README "Imagery" no-photo tile: `sunken`, `text-tertiary` fork-and-knife
///
/// Corners default to `radius-2xl` (README: "`radius-2xl` (in lists)") with the
/// `line` hairline ring at `opacity-30` (`.dsHairline`).
struct RecipeImageView: View {
    let recipe: Recipe?
    var photoPath: String? = nil
    var cuisine: String? = nil
    var cornerRadius: CGFloat = DS.Radius.xl2

    @Environment(FoodStore.self) private var store

    init(
        recipe: Recipe?,
        photoPath: String? = nil,
        cuisine: String? = nil,
        cornerRadius: CGFloat = DS.Radius.xl2
    ) {
        self.recipe = recipe
        self.photoPath = photoPath
        self.cuisine = cuisine
        self.cornerRadius = cornerRadius
    }

    init(photoPath: String?, cuisine: String? = nil, cornerRadius: CGFloat = DS.Radius.xl2) {
        self.recipe = nil
        self.photoPath = photoPath
        self.cuisine = cuisine
        self.cornerRadius = cornerRadius
    }

    private var resolvedPhotoPath: String? {
        if let photoPath, !photoPath.isEmpty {
            return photoPath
        }
        guard let recipe else { return nil }
        return store.photos(for: recipe).first ?? recipe.photoPaths.first ?? recipe.recipePhotoPaths.first
    }

    private var photoBucket: String {
        if let path = resolvedPhotoPath, let recipe, (recipe.recipePhotoPaths.contains(path) || recipe.photoPaths.contains(path)) {
            return SupabaseConfig.recipeBucket
        }
        return SupabaseConfig.photoBucket
    }

    private var resolvedCuisine: String? {
        cuisine ?? recipe?.cuisine
    }

    var body: some View {
        ZStack {
            if let path = resolvedPhotoPath {
                RemoteMealPhoto(
                    path: path,
                    cornerRadius: cornerRadius,
                    bucket: photoBucket
                )
            } else if let assetName = Cuisine.assetImageName(for: resolvedCuisine) {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                DS.Color.sunken
                    .overlay {
                        Image(systemName: "fork.knife")
                            .textStyle(.sansXl, tone: .tertiary)
                    }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .dsHairline(radius: cornerRadius)
        .contentShape(Rectangle())
    }
}

#Preview {
    NomNomPreview { store in
        HStack(spacing: DS.Spacing.s4) {
            RecipeImageView(recipe: store.recipes.first)
                .frame(width: DS.Spacing.s20, height: DS.Spacing.s20)
            RecipeImageView(photoPath: nil, cuisine: "italian")
                .frame(width: DS.Spacing.s20, height: DS.Spacing.s20)
            RecipeImageView(photoPath: nil, cuisine: nil)
                .frame(width: DS.Spacing.s20, height: DS.Spacing.s20)
        }
        .padding(DS.Spacing.gutter)
    }
}
