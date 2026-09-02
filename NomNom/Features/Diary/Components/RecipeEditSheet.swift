import SwiftUI

/// Dedicated modal sheet for editing a recipe's name, instructions, effort, tags, and merging.
struct RecipeEditSheet: View {
    let recipeID: UUID

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var recipeDraft = FoodStore.RecipeDraft()
    @State private var tagsText: String = ""
    @State private var isSaving = false
    @State private var mergeTarget: Recipe?
    @State private var confirmMerge = false

    private var recipe: Recipe? { store.recipe(recipeID) }
    private var history: [Meal] { store.servings(of: recipeID) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let recipe {
                        SectionCard("Recipe Name") {
                            TextField("Recipe name", text: $name)
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
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if !mergeCandidates(excluding: recipe).isEmpty {
                            SectionCard("Recipe Actions") {
                                VStack(alignment: .leading, spacing: 8) {
                                    Menu {
                                        ForEach(mergeCandidates(excluding: recipe)) { candidate in
                                            Button(candidate.name) {
                                                mergeTarget = candidate
                                                confirmMerge = true
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text("Merge into another recipe")
                                                .font(.subheadline.weight(.medium))
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }

                                    Text("Merging moves every logged meal onto the other recipe and keeps its name.")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else {
                        ContentUnavailableView("Recipe not found", systemImage: "questionmark.folder")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .screenTitle("Edit Recipe", displayMode: .inline)
            .sheetCommitToolbar(
                isSaving: isSaving,
                canSave: !name.trimmedName.isEmpty,
                onSave: save
            )
            .onAppear(perform: populate)
            .confirmationDialog(
                "Merge into “\(mergeTarget?.name ?? "")”?",
                isPresented: $confirmMerge,
                titleVisibility: .visible
            ) {
                Button("Merge \(history.count) meal\(history.count == 1 ? "" : "s")", role: .destructive) {
                    if let recipe, let mergeTarget {
                        Task {
                            await store.merge(recipe: recipe, into: mergeTarget)
                            dismiss()
                        }
                    }
                    mergeTarget = nil
                }
                Button("Cancel", role: .cancel) { mergeTarget = nil }
            } message: {
                Text("“\(recipe?.name ?? "")” will be removed and its history kept under the other name.")
            }
        }
    }

    private func populate() {
        guard let recipe else { return }
        name = recipe.name
        tagsText = recipe.tags.joined(separator: ", ")

        recipeDraft = FoodStore.RecipeDraft(
            text: recipe.recipeText,
            existingPhotoPaths: recipe.recipePhotoPaths,
            addedPhotoData: [],
            removedPhotoPaths: [],
            effort: recipe.effort,
            cuisine: recipe.cuisine,
            isPublic: recipe.isPublic
        )
    }

    private func save() {
        guard let recipe else { return }
        let trimmedName = name.trimmedName
        guard !trimmedName.isEmpty else { return }

        isSaving = true
        Task {
            if trimmedName != recipe.name {
                await store.rename(recipe: recipe, to: trimmedName)
            }
            let parsedTags = TagsParser.parse(tagsText)
            try? await store.addTags(parsedTags, to: recipe)
            try? await store.applyRecipe(recipeDraft, to: recipe)
            isSaving = false
            dismiss()
        }
    }

    private func mergeCandidates(excluding recipe: Recipe) -> [Recipe] {
        store.myRecipes
            .filter { $0.id != recipe.id }
            .sorted {
                Fuzzy.similarity($0.normalizedName, recipe.normalizedName) >
                Fuzzy.similarity($1.normalizedName, recipe.normalizedName)
            }
            .prefix(8)
            .map { $0 }
    }
}
