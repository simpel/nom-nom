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

    var body: some View {
        SectionCard("Pick recipe") {
            if title.trimmedName.isEmpty {
                Button(action: onPickRecipe) {
                    HStack(spacing: 12) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pick a recipe")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("Choose from past recipes or type a new one")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
            } else {
                selectedRecipeRow
            }
        }
    }

    private var selectedRecipeRow: some View {
        HStack(spacing: 12) {
            if !recipePhotos.isEmpty {
                MiniPhotoArcDeck(photoPaths: recipePhotos)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if isExistingRecipe {
                    if let recipe = existingMatchedRecipe, !recipe.tags.isEmpty {
                        Text(recipe.tags.joined(separator: " • "))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    Text("New recipe")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

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
                Image(systemName: "ellipsis")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onPickRecipe()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onRemoveRecipe) {
                Label("Remove", systemImage: "trash")
            }
        }
        .contextMenu {
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
        }
    }
}

typealias MealEditorDishSection = MealEditorRecipeSection
