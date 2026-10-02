import SwiftUI

/// Dedicated modal sheet for editing an existing recipe with the multi-step recipe flow.
struct RecipeEditSheet: View {
    let recipeID: UUID

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var coverPhotosDraft = FoodStore.PhotosDraft()
    @State private var recipeDraft = FoodStore.RecipeDraft()
    @State private var navigateToDetails = false
    @State private var didLoad = false

    private var recipe: Recipe? { store.recipe(recipeID) }
    private var isOwner: Bool { recipe?.ownerID == store.userID }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.block) {
                    if recipe != nil {
                        if isOwner {
                            RecipeBasicsForm(
                                name: $name,
                                coverPhotos: $coverPhotosDraft,
                                effort: $recipeDraft.effort,
                                cuisine: $recipeDraft.cuisine
                            )
                        } else {
                            EmptyState(
                                "Only the creator can edit this",
                                message: "Ask whoever added this recipe to change its details.",
                                layout: .screen
                            )
                        }
                    } else {
                        EmptyState("Recipe is gone", message: "It was deleted.", layout: .screen)
                    }
                }
                .padding(.horizontal, DS.Spacing.gutter)
                .padding(.top, DS.Spacing.s5)
                .padding(.bottom, DS.Spacing.s11)
            }
            .background(DS.Color.sheet)
            .screenTitle("Edit Recipe", displayMode: .inline)
            .sheetNextToolbar(canProceed: !name.trimmedName.isEmpty && isOwner) {
                navigateToDetails = true
            }
            .navigationDestination(isPresented: $navigateToDetails) {
                RecipeDetailsStepView(
                    recipeID: recipeID,
                    name: name,
                    coverPhotosDraft: coverPhotosDraft,
                    recipeDraft: $recipeDraft,
                    onDismiss: { dismiss() }
                )
            }
            .onAppear(perform: populate)
        }
        .dsSheet()
    }

    private func populate() {
        guard !didLoad, let recipe else { return }
        didLoad = true
        name = recipe.name
        coverPhotosDraft = FoodStore.PhotosDraft(existingPaths: recipe.photoPaths)

        recipeDraft = FoodStore.RecipeDraft(
            ingredients: recipe.ingredients,
            instructions: recipe.instructions,
            existingPhotoPaths: recipe.recipePhotoPaths,
            addedPhotoData: [],
            removedPhotoPaths: [],
            effort: recipe.effort,
            cuisine: recipe.cuisine,
            cuisineID: recipe.cuisineID,
            cookingMethodID: recipe.cookingMethodID,
            dishKindID: recipe.dishKindID,
            isPublic: recipe.isPublic
        )
    }
}
