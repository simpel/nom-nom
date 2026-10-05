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
                VStack(spacing: DS.Spacing.block) {
                    SectionCard("Recipe Name") {
                        Input("Recipe name", text: $dishName, appearance: .plain)
                            .autocorrectionDisabled()
                    }

                    RecipeEditorSection(draft: $recipeDraft)

                    MealEditorCookingTimeSection(effort: $recipeDraft.effort)
                }
                .padding(.horizontal, DS.Spacing.gutter)
                .padding(.top, DS.Spacing.s5)
                .padding(.bottom, DS.Spacing.s11)
            }
            .background(DS.Color.sheet)
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
        .dsSheet()
    }
}
