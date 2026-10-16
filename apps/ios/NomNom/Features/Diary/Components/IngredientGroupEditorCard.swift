import SwiftUI

/// One ingredient group in the recipe editor: a list Card of swipe-to-delete ingredient
/// rows (tap to edit) ending in "Add Ingredient". Rows reorder by drag (Reorder): within
/// the group, onto a row of another group, or into another group's card, an empty one
/// too. VoiceOver gets Move up, Move down and Move to {group}.
struct IngredientGroupEditorCard: View {
    let groupID: UUID?
    let ingredients: [RecipeIngredient]
    /// The groups a row can move to (every group but this one), named as their headers.
    var otherGroups: [IngredientGroup] = []
    @Binding var openRowID: UUID?
    @Binding var dragging: UUID?
    var onEdit: (RecipeIngredient) -> Void
    var onRemove: (RecipeIngredient) -> Void
    /// Puts the first ingredient where the second one is.
    var onMove: (UUID, UUID) -> Void
    var onMoveToGroup: (UUID, UUID) -> Void
    var onAdd: () -> Void

    var body: some View {
        Card(layout: .list) {
            ForEach(Array(ingredients.enumerated()), id: \.element.id) { index, item in
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
                    // On the row, not the SwipeRow, so the swipe's action strip stays behind it.
                    .reorderable(
                        item.id,
                        dragging: $dragging,
                        axis: .vertical,
                        previous: index > 0 ? ingredients[index - 1].id : nil,
                        next: index < ingredients.count - 1 ? ingredients[index + 1].id : nil,
                        onMove: onMove
                    )
                    .accessibilityActions {
                        ForEach(otherGroups) { group in
                            Button("Move to \(group.title ?? "Ingredients")") { onMoveToGroup(item.id, group.id) }
                        }
                    }
                }
            }

            AppButton("Add Ingredient", icon: "plus", appearance: .ghost, size: .sm, action: onAdd)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .reorderDropTarget(dragging: $dragging) { moved in
            if let groupID { onMoveToGroup(moved, groupID) }
        }
    }
}
