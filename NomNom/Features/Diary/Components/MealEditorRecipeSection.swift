import SwiftUI

/// Section in MealEditorView handling recipe selection, status chips, and recipe edit/remove shortcuts.
struct MealEditorRecipeSection: View {
    @Binding var title: String
    let existingMatchedRecipe: Recipe?
    let isExistingRecipe: Bool
    let onPickRecipe: () -> Void
    let onEditRecipe: () -> Void
    let onRemoveRecipe: () -> Void

    @Environment(FoodStore.self) private var store

    init(
        title: Binding<String>,
        existingMatchedRecipe: Recipe?,
        isExistingRecipe: Bool,
        onPickRecipe: @escaping () -> Void,
        onEditRecipe: @escaping () -> Void,
        onRemoveRecipe: @escaping () -> Void
    ) {
        self._title = title
        self.existingMatchedRecipe = existingMatchedRecipe
        self.isExistingRecipe = isExistingRecipe
        self.onPickRecipe = onPickRecipe
        self.onEditRecipe = onEditRecipe
        self.onRemoveRecipe = onRemoveRecipe
    }

    // Compatibility init
    init(
        title: Binding<String>,
        existingMatchedDish: Recipe?,
        isExistingDish: Bool,
        onPickDish: @escaping () -> Void,
        onEditRecipe: @escaping () -> Void,
        onRemoveDish: @escaping () -> Void
    ) {
        self._title = title
        self.existingMatchedRecipe = existingMatchedDish
        self.isExistingRecipe = isExistingDish
        self.onPickRecipe = onPickDish
        self.onEditRecipe = onEditRecipe
        self.onRemoveRecipe = onRemoveDish
    }

    private var recipePhotos: [String] {
        guard let recipe = existingMatchedRecipe else { return [] }
        return store.photos(for: recipe)
    }

    private var isCreator: Bool {
        guard let recipe = existingMatchedRecipe else { return true }
        return recipe.ownerID == store.userID
    }

    private var displayPhotoItems: [HeroPhotoItem] {
        guard let recipe = existingMatchedRecipe else { return [] }
        var items: [HeroPhotoItem] = []
        var paths: [String] = []
        for p in recipe.recipePhotoPaths where !paths.contains(p) {
            paths.append(p)
            items.append(.remote(path: p, bucket: SupabaseConfig.recipeBucket))
        }
        for p in recipe.photoPaths where !paths.contains(p) {
            paths.append(p)
            items.append(.remote(path: p, bucket: SupabaseConfig.photoBucket))
        }
        for p in store.photos(for: recipe) where !paths.contains(p) {
            paths.append(p)
            items.append(.remote(path: p, bucket: SupabaseConfig.photoBucket))
        }
        return Array(items.prefix(FoodStore.PhotosDraft.maxCount))
    }

    var body: some View {
        if title.trimmedName.isEmpty {
            emptyRecipeDeckView
        } else {
            heroRecipeSelectedView
        }
    }

    private var emptyRecipeDeckView: some View {
        EmptyRecipeDeckHeroView(onTap: onPickRecipe)
            .frame(height: 228)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .padding(.bottom, 6)
    }

    private var heroRecipeSelectedView: some View {
        VStack(spacing: 12) {
            HeroPhotoDeckView(
                items: displayPhotoItems,
                cuisine: existingMatchedRecipe?.cuisine,
                cardWidth: 144,
                cardHeight: 192
            )
            .frame(height: 228)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)

            VStack(spacing: 4) {
                if let cuisineName = Cuisine.formatDisplayName(existingMatchedRecipe?.cuisine) {
                    Text(cuisineName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DS.Color.accentText)
                }

                Text(title)
                    .font(AppTypography.pageTitleFont)
                    .foregroundStyle(DS.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            Menu {
                Button(action: onPickRecipe) {
                    Label("Change Recipe", systemImage: "arrow.triangle.2.circlepath")
                }

                if isCreator {
                    Button(action: onEditRecipe) {
                        Label("Edit Recipe Details", systemImage: "square.and.pencil")
                    }
                }

                Button(role: .destructive, action: onRemoveRecipe) {
                    Label("Remove", systemImage: "trash")
                }
            } label: {
                SubtleCapsuleLabel(title: "Change recipe", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 6)
    }
}

typealias MealEditorDishSection = MealEditorRecipeSection
