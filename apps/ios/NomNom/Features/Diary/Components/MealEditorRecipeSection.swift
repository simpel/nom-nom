import SwiftUI

/// Section in MealEditorView handling recipe selection, status chips, and recipe edit/remove shortcuts.
struct MealEditorRecipeSection: View {
    @Binding var title: String
    let existingMatchedRecipe: Recipe?
    let isExistingRecipe: Bool
    let onPickRecipe: () -> Void
    let onCreateRecipe: () -> Void
    let onEditRecipe: () -> Void
    let onRemoveRecipe: () -> Void

    @Environment(FoodStore.self) private var store

    init(
        title: Binding<String>,
        existingMatchedRecipe: Recipe?,
        isExistingRecipe: Bool,
        onPickRecipe: @escaping () -> Void,
        onCreateRecipe: @escaping () -> Void,
        onEditRecipe: @escaping () -> Void,
        onRemoveRecipe: @escaping () -> Void
    ) {
        self._title = title
        self.existingMatchedRecipe = existingMatchedRecipe
        self.isExistingRecipe = isExistingRecipe
        self.onPickRecipe = onPickRecipe
        self.onCreateRecipe = onCreateRecipe
        self.onEditRecipe = onEditRecipe
        self.onRemoveRecipe = onRemoveRecipe
    }

    private var isCreator: Bool {
        guard let recipe = existingMatchedRecipe else { return true }
        return recipe.ownerID == store.userID
    }

    /// The recipe's photo, resolved as PhotoCard does it: meal photos, recipe photos, then the cuisine's photograph.
    private var recipeAvatar: Avatar {
        guard let recipe = existingMatchedRecipe else { return Avatar(name: title) }
        let photo = PhotoCardSource.recipe(recipe).resolved(in: store)
        return Avatar(name: recipe.name, photoPath: photo.path, bucket: photo.bucket, assetName: photo.cuisineAsset)
    }

    var body: some View {
        Group {
            if title.trimmedName.isEmpty {
                ScreenHeader(
                    "What did you cook?",
                    summary: "Pick it from your recipes, or create a new one.",
                    centered: true,
                    actions: [
                        .init(title: "Pick recipe", action: onPickRecipe),
                        .init(title: "Create recipe", variant: .secondary, appearance: .soft, action: onCreateRecipe)
                    ]
                )
            } else {
                selectedRecipe
            }
        }
        .padding(.bottom, DS.Spacing.block)
    }

    private var selectedRecipe: some View {
        VStack(spacing: DS.Spacing.s4) {
            ScreenHeader(
                title,
                eyebrow: Cuisine.formatDisplayName(existingMatchedRecipe?.cuisine),
                avatar: recipeAvatar
            )

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
                    size: .md
                )
            }
            .buttonStyle(AppPressableButtonStyle())
        }
        .frame(maxWidth: .infinity)
    }
}
