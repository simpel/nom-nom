import SwiftUI

/// Sheet to view and edit recipe and tags for a dish in meal editor.
struct DishRecipeEditSheet: View {
    @Binding var dishName: String
    @Binding var recipeDraft: FoodStore.RecipeDraft
    @Binding var tagsText: String

    @Environment(\.dismiss) private var dismiss

    @State private var initialDishName: String = ""
    @State private var initialRecipeDraft = FoodStore.RecipeDraft()
    @State private var initialTagsText: String = ""
    @State private var didCaptureInitial = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SectionCard("Recipe Name") {
                        TextField("Recipe name", text: $dishName)
                            .autocorrectionDisabled()
                    }

                    RecipeEditorSection(draft: $recipeDraft)

                    SectionCard("Cooking Effort") {
                        TactileOptionPicker(selection: $recipeDraft.effort)
                    }

                    SectionCard("Tags") {
                        TextField("Tags, comma separated", text: $tagsText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .screenTitle("Edit Recipe", displayMode: .inline)
            .sheetCommitToolbar(
                canSave: !dishName.trimmedName.isEmpty,
                onCancel: {
                    dishName = initialDishName
                    recipeDraft = initialRecipeDraft
                    tagsText = initialTagsText
                    dismiss()
                },
                onSave: {
                    dismiss()
                }
            )
            .onAppear {
                if !didCaptureInitial {
                    initialDishName = dishName
                    initialRecipeDraft = recipeDraft
                    initialTagsText = tagsText
                    didCaptureInitial = true
                }
            }
        }
    }
}
