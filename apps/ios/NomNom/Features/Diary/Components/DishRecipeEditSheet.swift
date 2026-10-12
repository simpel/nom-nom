import SwiftUI

/// Sheet to view and edit recipe for a dish in meal editor. Works on a copy and writes
/// the name and recipe back to the meal editor only when saved.
struct DishRecipeEditSheet: View {
    @Binding var dishName: String
    @Binding var recipeDraft: FoodStore.RecipeDraft

    @State private var session: FormSession<RecipeForm>

    init(dishName: Binding<String>, recipeDraft: Binding<FoodStore.RecipeDraft>) {
        self._dishName = dishName
        self._recipeDraft = recipeDraft
        let form = RecipeForm(name: dishName.wrappedValue, recipe: recipeDraft.wrappedValue)
        self._session = State(initialValue: FormSession(form))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.block) {
                    SectionCard("Recipe Name") {
                        Input("Recipe name", text: $session.form.name, appearance: .plain)
                            .autocorrectionDisabled()
                    }

                    RecipeEditorSection(draft: $session.form.recipe)

                    MealEditorCookingTimeSection(effort: $session.form.recipe.effort)
                }
                .padding(.horizontal, DS.Spacing.gutter)
                .padding(.top, DS.Spacing.s5)
                .padding(.bottom, DS.Spacing.s11)
            }
            .background(DS.Color.sheet)
            .screenTitle("Edit Recipe", displayMode: .inline)
            .sheetCommitToolbar(session) { form in
                dishName = form.name
                recipeDraft = form.recipe
            }
        }
        .editorSheet(session)
    }
}
