import SwiftUI

/// One ingredient group in the recipe editor: a list Card of swipe-to-delete ingredient
/// rows (tap to edit) ending in "Add Ingredient".
struct IngredientGroupEditorCard: View {
    let ingredients: [RecipeIngredient]
    @Binding var openRowID: UUID?
    var onEdit: (RecipeIngredient) -> Void
    var onRemove: (RecipeIngredient) -> Void
    var onAdd: () -> Void

    var body: some View {
        Card(layout: .list) {
            ForEach(ingredients) { item in
                SwipeActionRow(
                    id: item.id,
                    openRowID: $openRowID,
                    trailingIcon: "trash",
                    trailingColor: DS.Color.destructive,
                    onTrailingAction: { onRemove(item) }
                ) {
                    ListRow(
                        item.trimmedIngredient.isEmpty ? "New ingredient" : item.trimmedIngredient,
                        value: item.formattedAmount,
                        leading: .icon("line.3.horizontal"),
                        action: { onEdit(item) }
                    )
                    .valueSemibold()
                    .titleLines(nil)
                }
            }

            AppButton("Add Ingredient", icon: "plus", appearance: .ghost, size: .sm, action: onAdd)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
