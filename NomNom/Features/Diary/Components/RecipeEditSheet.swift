import SwiftUI

/// Dedicated modal sheet for editing an existing recipe with the multi-step recipe flow.
struct RecipeEditSheet: View {
    let recipeID: UUID

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var coverPhotosDraft = FoodStore.PhotosDraft()
    @State private var recipeDraft = FoodStore.RecipeDraft()
    @State private var tagsText: String = ""
    @State private var navigateToDetails = false
    @State private var didLoad = false

    private var recipe: Recipe? { store.recipe(recipeID) }
    private var isOwner: Bool { recipe?.ownerID == store.userID }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.section) {
                    if let recipe {
                        if isOwner {
                            AssetPhotosPickerSection(draft: $coverPhotosDraft, title: "Cover Photo")

                            SectionCard("Recipe Name") {
                                TextField("Recipe name (e.g. Carbonara)", text: $name)
                                    .autocorrectionDisabled()
                            }

                            SectionCard("Cooking Effort") {
                                TactileOptionPicker(selection: $recipeDraft.effort)
                            }

                            CuisinePickerSection(selection: $recipeDraft.cuisine)
                        } else {
                            ContentUnavailableView(
                                "Creator Only",
                                systemImage: "lock.fill",
                                description: Text("Only the creator of this recipe can edit its details.")
                            )
                        }
                    } else {
                        ContentUnavailableView("Recipe not found", systemImage: "questionmark.folder")
                    }
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("Edit Recipe", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Cancel")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Next") {
                        navigateToDetails = true
                    }
                    .disabled(name.trimmedName.isEmpty || !isOwner)
                    .fontWeight(.semibold)
                }
            }
            .navigationDestination(isPresented: $navigateToDetails) {
                RecipeDetailsStepView(
                    recipeID: recipeID,
                    name: name,
                    coverPhotosDraft: coverPhotosDraft,
                    recipeDraft: $recipeDraft,
                    tagsText: $tagsText,
                    onDismiss: { dismiss() }
                )
            }
            .onAppear(perform: populate)
        }
    }

    private func populate() {
        guard !didLoad, let recipe else { return }
        didLoad = true
        name = recipe.name
        tagsText = recipe.tags.joined(separator: ", ")
        coverPhotosDraft = FoodStore.PhotosDraft(existingPaths: recipe.photoPaths)

        recipeDraft = FoodStore.RecipeDraft(
            ingredients: recipe.ingredients,
            instructions: recipe.instructions,
            existingPhotoPaths: recipe.recipePhotoPaths,
            addedPhotoData: [],
            removedPhotoPaths: [],
            effort: recipe.effort,
            cuisine: recipe.cuisine,
            isPublic: recipe.isPublic
        )
    }
}
