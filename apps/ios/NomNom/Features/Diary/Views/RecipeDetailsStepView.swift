import SwiftUI

/// Step 2 of creating or editing a recipe: ingredients, instructions, and sharing visibility.
struct RecipeDetailsStepView: View {
    var recipeID: UUID? = nil
    let name: String
    let coverPhotosDraft: FoodStore.PhotosDraft
    @Binding var recipeDraft: FoodStore.RecipeDraft
    var onCreated: ((Recipe) -> Void)?
    var onDismiss: () -> Void

    @Environment(FoodStore.self) private var store
    @State private var isSaving = false

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.block) {
                RecipeEditorSection(draft: $recipeDraft)

                VisibilityToggleCard.recipe(isPublic: $recipeDraft.isPublic)
            }
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s5)
            .padding(.bottom, DS.Spacing.s11)
        }
        .background(DS.Color.sheet)
        .screenTitle("Recipe Details", displayMode: .inline)
        .stepCommitToolbar(isSaving: isSaving, onSave: save)
        .alert("Couldn't save recipe",
               isPresented: Binding(get: { store.errorMessage != nil },
                                    set: { if !$0 { store.errorMessage = nil } })) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private func save() {
        let trimmedName = name.trimmedName
        guard !trimmedName.isEmpty else { return }

        isSaving = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            do {
                if let recipeID, let recipe = store.recipe(recipeID) {
                    if trimmedName != recipe.name {
                        await store.rename(recipe: recipe, to: trimmedName)
                    }
                    try await store.applyCoverPhotos(coverPhotosDraft, to: recipe)
                    try await store.applyRecipe(recipeDraft, to: recipe)
                    isSaving = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onCreated?(recipe)
                    onDismiss()
                } else {
                    let recipe = try await store.findOrCreateRecipe(
                        named: trimmedName,
                        cuisine: recipeDraft.cuisine,
                        cuisineID: recipeDraft.cuisineID,
                        cookingMethodID: recipeDraft.cookingMethodID,
                        dishKindID: recipeDraft.dishKindID,
                        serves: recipeDraft.serves,
                        isPublic: recipeDraft.isPublic
                    )
                    try await store.applyCoverPhotos(coverPhotosDraft, to: recipe)
                    try await store.applyRecipe(recipeDraft, to: recipe)

                    if coverPhotosDraft.isEmpty {
                        Task {
                            try? await store.generateRecipeImage(for: recipe)
                        }
                    }

                    isSaving = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onCreated?(recipe)
                    onDismiss()
                }
            } catch {
                isSaving = false
            }
        }
    }
}
