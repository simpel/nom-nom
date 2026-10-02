import SwiftUI

/// Step 2 of logging a new dish: attach recipe (text or photos) and details before verdicts.
struct MealRecipeStepView: View {
    @Binding var draft: FoodStore.MealDraft
    var onDismiss: () -> Void

    @Environment(FoodStore.self) private var store
    @State private var recipeDraft = FoodStore.RecipeDraft()
    @State private var navigateToVerdict = false

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.block) {
                SectionCard {
                    Text(draft.dishName).textStyle(.serifSm)
                    Text("New dish — add a recipe to remember how you made it.")
                        .textStyle(.sansMd, tone: .secondary)
                }

                RecipeEditorSection(draft: $recipeDraft)

                MealEditorCookingTimeSection(effort: $recipeDraft.effort)
            }
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s5)
            .padding(.bottom, DS.Spacing.s11)
        }
        .background(DS.Color.sheet)
        .screenTitle("Recipe & Details", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Next") {
                    draft.recipe = recipeDraft
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
        }
    }
}
