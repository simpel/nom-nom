import SwiftUI

/// Step 2 (last) of logging a meal: Photos, cooking time / effort, and dinner parties.
/// MealEditorView adds the save toolbar (`.stepCommitToolbar`).
struct MealDetailsStepView: View {
    @Binding var draft: FoodStore.MealDraft

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.block) {
                Input(
                    "Name this meal",
                    label: "Name (optional)",
                    text: $draft.mealTitle,
                    hint: "Leave blank to use \(draft.dishName)."
                )

                AssetPhotosPickerSection(draft: $draft.photos)

                MealEditorCookingTimeSection(effort: $draft.effort)

                MealEditorPartiesSection(
                    selectedParties: Binding(
                        get: { draft.servedParties ?? [] },
                        set: { draft.servedParties = $0 }
                    )
                )
            }
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s5)
            .padding(.bottom, DS.Spacing.s11)
        }
        .background(DS.Color.sheet)
        .screenTitle("Details", displayMode: .inline)
    }
}
