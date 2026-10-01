import SwiftUI

/// Sheet to view and edit recipe for a dish in meal editor.
struct DishRecipeEditSheet: View {
    @Binding var dishName: String
    @Binding var recipeDraft: FoodStore.RecipeDraft

    @Environment(\.dismiss) private var dismiss

    @State private var initialDishName: String = ""
    @State private var initialRecipeDraft = FoodStore.RecipeDraft()
    @State private var didCaptureInitial = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SectionCard("Recipe Name") {
                        Input("Recipe name", text: $dishName, style: .cardRow)
                            .autocorrectionDisabled()
                    }

                    RecipeEditorSection(draft: $recipeDraft)

                    MealEditorCookingTimeSection(effort: $recipeDraft.effort)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(DS.Color.bg)
            .screenTitle("Edit Recipe", displayMode: .inline)
            .sheetCommitToolbar(
                canSave: !dishName.trimmedName.isEmpty,
                onCancel: {
                    dishName = initialDishName
                    recipeDraft = initialRecipeDraft
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
                    didCaptureInitial = true
                }
            }
        }
    }
}
