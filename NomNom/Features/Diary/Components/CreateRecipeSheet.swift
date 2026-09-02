import SwiftUI

/// Dedicated modal sheet for creating a new recipe with name, instructions, effort, and tags.
struct CreateRecipeSheet: View {
    var initialName: String = ""
    var onCreated: ((Recipe) -> Void)?

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var recipeDraft = FoodStore.RecipeDraft()
    @State private var tagsText: String = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SectionCard("Recipe Name") {
                        TextField("Recipe name (e.g. Carbonara)", text: $name)
                            .autocorrectionDisabled()
                    }

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
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(DS.Color.bg)
            .screenTitle("New Recipe", displayMode: .inline)
            .sheetCommitToolbar(
                isSaving: isSaving,
                canSave: !name.trimmedName.isEmpty,
                onSave: save
            )
            .onAppear {
                if name.isEmpty && !initialName.isEmpty {
                    name = initialName
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
                try await store.applyRecipe(recipeDraft, to: recipe)
                isSaving = false
                onCreated?(recipe)
                dismiss()
            } catch {
                isSaving = false
            }
        }
    }
}
