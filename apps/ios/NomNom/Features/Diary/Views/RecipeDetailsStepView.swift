import SwiftUI

/// Step 2 of creating or editing a recipe: ingredients, instructions, and sharing visibility.
struct RecipeDetailsStepView: View {
    var recipeID: UUID? = nil
    @Bindable var session: FormSession<RecipeForm>
    var onCreated: ((Recipe) -> Void)?

    @Environment(FoodStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.block) {
                RecipeEditorSection(draft: $session.form.recipe)

                VisibilityToggleCard.recipe(isPublic: $session.form.recipe.isPublic)
            }
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s5)
            .padding(.bottom, DS.Spacing.s11)
        }
        .background(DS.Color.sheet)
        .screenTitle("Recipe Details", displayMode: .inline)
        .stepCommitToolbar(session, save: save)
    }

    private func save(_ form: RecipeForm) async throws {
        let name = form.name.trimmedName
        let draft = form.recipe
        let recipe: Recipe
        if let recipeID, let existing = store.recipe(recipeID) {
            recipe = existing
            if name != existing.name {
                await store.rename(recipe: existing, to: name)
                try store.throwIfFailed()
            }
        } else {
            recipe = try await store.findOrCreateRecipe(
                named: name,
                cuisine: draft.cuisine,
                cuisineID: draft.cuisineID,
                cookingMethodID: draft.cookingMethodID,
                dishKindID: draft.dishKindID,
                serves: draft.serves,
                isPublic: draft.isPublic
            )
        }
        try await store.applyCoverPhotos(form.coverPhotos, to: recipe)
        try await store.applyRecipe(draft, to: recipe)

        if recipeID == nil && form.coverPhotos.isEmpty {
            Task { try? await store.generateRecipeImage(for: recipe) }
        }
        onCreated?(recipe)
    }
}
