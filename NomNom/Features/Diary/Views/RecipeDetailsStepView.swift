import SwiftUI

/// Step 2 of creating or editing a recipe: ingredients, instructions, tags, and sharing visibility.
struct RecipeDetailsStepView: View {
    var recipeID: UUID? = nil
    let name: String
    let coverPhotosDraft: FoodStore.PhotosDraft
    @Binding var recipeDraft: FoodStore.RecipeDraft
    @Binding var tagsText: String
    var onCreated: ((Recipe) -> Void)?
    var onDismiss: () -> Void

    @Environment(FoodStore.self) private var store
    @State private var isSaving = false

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.section) {
                RecipeEditorSection(draft: $recipeDraft)

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
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.screenHorizontal)
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
        .background(DS.Color.bg)
        .screenTitle("Recipe Details", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isSaving {
                    ProgressView().controlSize(.small)
                } else {
                    Button {
                        save()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isSaving)
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
                let parsedTags = TagsParser.parse(tagsText)
                if let recipeID, let recipe = store.recipe(recipeID) {
                    if trimmedName != recipe.name {
                        await store.rename(recipe: recipe, to: trimmedName)
                    }
                    try await store.addTags(parsedTags, to: recipe)
                    try await store.applyCoverPhotos(coverPhotosDraft, to: recipe)
                    try await store.applyRecipe(recipeDraft, to: recipe)
                    isSaving = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onCreated?(recipe)
                    onDismiss()
                } else {
                    let recipe = try await store.findOrCreateRecipe(
                        named: trimmedName,
                        tags: parsedTags,
                        cuisine: recipeDraft.cuisine,
                        isPublic: recipeDraft.isPublic
                    )
                    try await store.applyCoverPhotos(coverPhotosDraft, to: recipe)
                    try await store.applyRecipe(recipeDraft, to: recipe)
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
