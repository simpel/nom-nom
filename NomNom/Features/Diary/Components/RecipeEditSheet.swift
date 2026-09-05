import SwiftUI

/// Dedicated modal sheet for editing a recipe's name, instructions, effort, and tags.
struct RecipeEditSheet: View {
    let recipeID: UUID

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var coverPhotosDraft = FoodStore.PhotosDraft()
    @State private var recipeDraft = FoodStore.RecipeDraft()
    @State private var tagsText: String = ""
    @State private var isSaving = false

    private var recipe: Recipe? { store.recipe(recipeID) }
    private var isOwner: Bool { recipe?.ownerID == store.userID }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.section) {
                    if let recipe {
                        if isOwner {
                            SectionCard("Recipe Name") {
                                TextField("Recipe name", text: $name)
                                    .autocorrectionDisabled()
                            }

                            AssetPhotosPickerSection(draft: $coverPhotosDraft, title: "Cover Photo")

                            RecipeEditorSection(draft: $recipeDraft)

                            CuisinePickerSection(selection: $recipeDraft.cuisine)

                            SectionCard("Cooking Effort") {
                                TactileOptionPicker(selection: $recipeDraft.effort)
                            }

                            SectionCard("Tags") {
                                TextField("Tags, comma separated (e.g. pasta, quick, oven)", text: $tagsText)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }

                            SectionCard("Sharing & Visibility") {
                                VStack(alignment: .leading, spacing: 6) {
                                    Toggle("Make recipe public", isOn: $recipeDraft.isPublic)
                                        .font(.body.weight(.medium))

                                    Text("When enabled, other dinner parties and users can discover and cook this recipe.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
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
            .sheetCommitToolbar(
                isSaving: isSaving,
                canSave: isOwner && !name.trimmedName.isEmpty,
                onSave: save
            )
            .onAppear(perform: populate)
        }
    }

    private func populate() {
        guard let recipe else { return }
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

    private func save() {
        guard let recipe, isOwner else { return }
        let trimmedName = name.trimmedName
        guard !trimmedName.isEmpty else { return }

        isSaving = true
        Task {
            if trimmedName != recipe.name {
                await store.rename(recipe: recipe, to: trimmedName)
            }
            let parsedTags = TagsParser.parse(tagsText)
            try? await store.addTags(parsedTags, to: recipe)
            try? await store.applyCoverPhotos(coverPhotosDraft, to: recipe)
            try? await store.applyRecipe(recipeDraft, to: recipe)
            isSaving = false
            dismiss()
        }
    }
}
