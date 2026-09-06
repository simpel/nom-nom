import SwiftUI

/// Step 2 of logging a new dish: attach recipe (text or photos) and tags/notes before verdicts.
struct MealRecipeStepView: View {
    @Binding var draft: FoodStore.MealDraft
    var onDismiss: () -> Void

    @Environment(FoodStore.self) private var store
    @State private var recipeDraft = FoodStore.RecipeDraft()
    @State private var tagsText = ""
    @State private var navigateToVerdict = false

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.section) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(draft.dishName)
                            .font(.title3.bold())
                        Text("New dish — add a recipe or tags to remember how you made it.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                RecipeEditorSection(draft: $recipeDraft)

                SectionCard("Cooking Effort") {
                    TactileOptionPicker(selection: $recipeDraft.effort)
                }

                SectionCard("Tags") {
                    Input("Tags, comma separated (e.g. quick, oven, pasta)", text: $tagsText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .padding(.horizontal, DS.Spacing.screenHorizontal)
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
        .background(DS.Color.bg)
        .navigationTitle("Recipe & Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Next") {
                    draft.recipe = recipeDraft
                    if !tagsText.trimmingCharacters(in: .whitespaces).isEmpty {
                        draft.tags = TagsParser.parse(tagsText)
                    }
                    navigateToVerdict = true
                }
                .fontWeight(.semibold)
            }
        }
        .navigationDestination(isPresented: $navigateToVerdict) {
            MealVerdictStepView(draft: draft, onDismiss: onDismiss)
        }
        .onAppear {
            if let existingRecipe = draft.recipe {
                recipeDraft = existingRecipe
            }
            tagsText = draft.tags.joined(separator: ", ")
        }
    }
}
