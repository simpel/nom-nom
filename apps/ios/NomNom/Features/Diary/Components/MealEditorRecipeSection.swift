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

    private var isCreator: Bool {
        guard let recipe = existingMatchedRecipe else { return true }
        return recipe.ownerID == store.userID
    }

    /// The recipe's own pages, its cover photos, then photos from meals made with it.
    private var recipePhotos: [PhotoCardSource] {
        guard let recipe = existingMatchedRecipe else { return [] }
        var seen: Set<String> = []
        var sources: [PhotoCardSource] = []
        let buckets = [
            (recipe.recipePhotoPaths, SupabaseConfig.recipeBucket),
            (recipe.photoPaths, SupabaseConfig.photoBucket),
            (store.photos(for: recipe), SupabaseConfig.photoBucket)
        ]
        for (paths, bucket) in buckets {
            for path in paths where seen.insert(path).inserted {
                sources.append(.remote(path: path, bucket: bucket, cuisine: recipe.cuisine))
            }
        }
        let capped = Array(sources.prefix(FoodStore.PhotosDraft.maxCount))
        return capped.isEmpty ? [.none(cuisine: recipe.cuisine)] : capped
    }

    var body: some View {
        Group {
            if title.trimmedName.isEmpty {
                EmptyState(
                    "No recipe yet",
                    message: "Choose what you cooked from your recipes, or start a new one.",
                    action: EmptyStateAction("Pick a recipe", perform: onPickRecipe)
                )
            } else {
                selectedRecipe
            }
        }
        .padding(.bottom, DS.Spacing.block)
    }

    private var selectedRecipe: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s5) {
            PhotoStrip(photos: recipePhotos.isEmpty ? [.none()] : recipePhotos, onSelect: { _ in })

            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                    if let cuisineName = Cuisine.formatDisplayName(existingMatchedRecipe?.cuisine) {
                        Text(cuisineName).textStyle(.sansSm, tone: .accent, weight: .semibold)
                    }
                    Text(title)
                        .textStyle(.serifSm)
                        .accessibilityAddTraits(.isHeader)
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
                    AppButtonLabel(
                        "Change recipe",
                        variant: .secondary,
                        appearance: .soft,
                        size: .sm
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

typealias MealEditorDishSection = MealEditorRecipeSection
