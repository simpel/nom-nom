import SwiftUI
import UniformTypeIdentifiers

/// Section in recipe editors for adding, modifying, and removing ingredients with distinct quantity, unit, and name.
/// Uses a Master-Detail pattern where rows are sortable, and editing happens in a full-sized sheet.
struct RecipeIngredientsEditorSection: View {
    @Binding var ingredients: [RecipeIngredient]

    @State private var editingIngredient: RecipeIngredient?
    @State private var openRowID: UUID?

    var body: some View {
        DSSection("Ingredients") {
            Card(layout: .list) {
                ForEach(ingredients) { item in
                    SwipeActionRow(
                        id: item.id,
                        openRowID: $openRowID,
                        trailingIcon: "trash",
                        trailingColor: DS.Color.destructive,
                        onTrailingAction: {
                            withAnimation(DS.Motion.layout) {
                                ingredients.removeAll { $0.id == item.id }
                            }
                        }
                    ) {
                        ListRow(
                            item.trimmedIngredient.isEmpty ? "New ingredient" : item.trimmedIngredient,
                            value: item.formattedAmount,
                            leading: .icon("line.3.horizontal"),
                            action: {
                                editingIngredient = item
                            }
                        )
                        .valueSemibold()
                        .titleLines(nil)
                    }
                }

                AppButton("Add Ingredient", icon: "plus", appearance: .ghost, size: .sm) {
                    editingIngredient = RecipeIngredient()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .sheet(item: $editingIngredient) { item in
            IngredientEditorSheet(
                initialIngredient: item,
                isNew: !ingredients.contains(where: { $0.id == item.id }),
                onSave: { updatedIngredient in
                    if let index = ingredients.firstIndex(where: { $0.id == updatedIngredient.id }) {
                        ingredients[index] = updatedIngredient
                    } else {
                        withAnimation(DS.Motion.layout) {
                            ingredients.append(updatedIngredient)
                        }
                    }
                },
                onRemove: {
                    withAnimation(DS.Motion.layout) {
                        ingredients.removeAll { $0.id == item.id }
                    }
                }
            )
        }
    }
}

