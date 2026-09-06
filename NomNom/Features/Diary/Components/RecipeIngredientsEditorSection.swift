import SwiftUI

/// Section in recipe editors for adding, modifying, and removing ingredients with distinct quantity, unit, and name.
struct RecipeIngredientsEditorSection: View {
    @Binding var ingredients: [RecipeIngredient]

    var body: some View {
        SectionCard("Ingredients") {
            VStack(spacing: 10) {
                ForEach($ingredients) { $item in
                    ingredientRow(item: $item)
                }

                AppButton(
                    "Add Ingredient",
                    systemImage: "plus",
                    variant: .secondary,
                    style: .ghost,
                    size: .sm
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        $ingredients.wrappedValue.append(RecipeIngredient())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, ingredients.isEmpty ? 2 : 4)
            }
        }
    }

    private func ingredientRow(item: Binding<RecipeIngredient>) -> some View {
        HStack(spacing: 8) {
            Input("Qty", text: item.quantity, size: .sm)
                .keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
                .frame(width: 58)

            Input("Unit", text: item.measurement, size: .sm)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .frame(width: 68)

            Input("Ingredient", text: item.ingredient, size: .sm)

            AppButton(
                systemImage: "minus.circle",
                variant: .destructive,
                style: .ghost,
                size: .sm
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    let targetID = item.wrappedValue.id
                    $ingredients.wrappedValue.removeAll { $0.id == targetID }
                }
            }
            .accessibilityLabel("Remove ingredient")
        }
    }
}
