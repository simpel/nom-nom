import SwiftUI

/// Section in recipe editors for adding, modifying, and removing ingredients with distinct quantity, unit, and name.
struct RecipeIngredientsEditorSection: View {
    @Binding var ingredients: [RecipeIngredient]

    var body: some View {
        SectionCard("Ingredients") {
            VStack(spacing: DS.Spacing.s2_5) {
                ForEach($ingredients) { $item in
                    ingredientRow(item: $item)
                }

                AppButton("Add Ingredient", icon: "plus", appearance: .ghost, size: .sm) {
                    withAnimation(DS.Motion.layout) {
                        $ingredients.wrappedValue.append(RecipeIngredient())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, ingredients.isEmpty ? DS.Spacing.s0_5 : DS.Spacing.s1)
            }
        }
    }

    private func ingredientRow(item: Binding<RecipeIngredient>) -> some View {
        HStack(spacing: DS.Spacing.s2) {
            Input("Qty", text: item.quantity)
                .keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
                .frame(width: DS.Spacing.s14)

            Input("Unit", text: item.measurement)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .frame(width: DS.Spacing.s16)

            Input("Ingredient", text: item.ingredient)

            AppButton(
                icon: "minus.circle",
                accessibilityLabel: "Remove ingredient",
                variant: .destructive,
                appearance: .ghost
            ) {
                withAnimation(DS.Motion.layout) {
                    let targetID = item.wrappedValue.id
                    $ingredients.wrappedValue.removeAll { $0.id == targetID }
                }
            }
        }
    }
}
