import SwiftUI

/// Step 2 of creating a recipe: ingredients, instructions, tags, and sharing visibility.
struct RecipeDetailsStepView: View {
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
    }

    private func save() {
        let trimmedName = name.trimmedName
        guard !trimmedName.isEmpty else { return }

        isSaving = true
        Task {
            do {
                let parsedTags = TagsParser.parse(tagsText)
                let recipe = try await store.findOrCreateRecipe(
                    named: trimmedName,
                    tags: parsedTags,
                    cuisine: recipeDraft.cuisine,
                    isPublic: recipeDraft.isPublic
                )
                try await store.applyCoverPhotos(coverPhotosDraft, to: recipe)
                try await store.applyRecipe(recipeDraft, to: recipe)
                isSaving = false
                onCreated?(recipe)
                onDismiss()
            } catch {
                isSaving = false
            }
        }
    }
}
