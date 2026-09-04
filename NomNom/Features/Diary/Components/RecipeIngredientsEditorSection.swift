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

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        $ingredients.wrappedValue.append(RecipeIngredient())
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.subheadline.weight(.semibold))
                        Text("Add Ingredient")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(DS.Color.accentText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, ingredients.isEmpty ? 2 : 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func ingredientRow(item: Binding<RecipeIngredient>) -> some View {
        HStack(spacing: 8) {
            TextField("Qty", text: item.quantity)
                .font(.subheadline)
                .keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
                .frame(width: 55)
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(DS.Color.sunken, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            TextField("Unit", text: item.measurement)
                .font(.subheadline)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .frame(width: 65)
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(DS.Color.sunken, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            TextField("Ingredient", text: item.ingredient)
                .font(.subheadline)
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(DS.Color.sunken, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    let targetID = item.wrappedValue.id
                    $ingredients.wrappedValue.removeAll { $0.id == targetID }
                }
            } label: {
                Image(systemName: "minus.circle")
                    .font(.body)
                    .foregroundStyle(DS.Color.textTertiary)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }
}
