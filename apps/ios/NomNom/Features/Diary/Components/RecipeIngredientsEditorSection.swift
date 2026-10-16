import SwiftUI

/// The ingredients in a recipe editor, in their groups ("Sauce", "Salad"). A recipe
/// without groups is one "Ingredients" section; once a group is added each group is its
/// own section, titled by its name, with "Edit" on the header. Rows edit in
/// IngredientEditorSheet and drag between places and groups (Reorder); groups rename and
/// move in IngredientGroupSheet.
struct RecipeIngredientsEditorSection: View {
    @Binding var groups: [IngredientGroup]

    @State private var editingIngredient: EditingIngredient?
    @State private var editingGroup: IngredientGroup?
    @State private var openRowID: UUID?
    @State private var dragging: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.block) {
            if groups.isUngrouped {
                DSSection("Ingredients") { card(for: groups.first) }
            } else {
                ForEach(groups) { group in
                    DSSection(
                        group.title ?? "Ingredients",
                        action: SectionAction("Edit", accessibilityLabel: "Edit \(group.title ?? "group")") { editingGroup = group }
                    ) {
                        card(for: group)
                    }
                }
            }

            AppButton("Add Group", icon: "plus", variant: .secondary, appearance: .ghost, size: .sm) {
                editingGroup = IngredientGroup()
            }
        }
        // A drop anywhere else in the section still ends the drag.
        .reorderDropTarget(dragging: $dragging) { _ in }
        .sheet(item: $editingIngredient) { editing in
            IngredientEditorSheet(
                initialIngredient: editing.ingredient,
                isNew: groups.location(of: editing.id) == nil,
                onSave: { save($0, in: editing.groupID) },
                onRemove: { remove(editing.ingredient) }
            )
        }
        .sheet(item: $editingGroup) { group in
            let position = groups.firstIndex { $0.id == group.id }
            IngredientGroupSheet(
                group: group,
                position: position ?? groups.count,
                groupCount: groups.count,
                isNew: position == nil,
                onSave: { form in withAnimation(DS.Motion.layout) { groups.save(form.group, at: form.position) } },
                onRemove: { withAnimation(DS.Motion.layout) { groups.removeAll { $0.id == group.id } } }
            )
        }
    }

    private func card(for group: IngredientGroup?) -> some View {
        IngredientGroupEditorCard(
            groupID: group?.id,
            ingredients: group?.ingredients ?? [],
            otherGroups: groups.filter { $0.id != group?.id },
            openRowID: $openRowID,
            dragging: $dragging,
            onEdit: { editingIngredient = EditingIngredient(groupID: group?.id, ingredient: $0) },
            onRemove: { item in withAnimation(DS.Motion.layout) { remove(item) } },
            onMove: { moved, target in groups.move(moved, toPlaceOf: target) },
            onMoveToGroup: { moved, id in groups.move(moved, toEndOf: id) },
            onAdd: { editingIngredient = EditingIngredient(groupID: group?.id, ingredient: RecipeIngredient()) }
        )
    }

    /// Updates the ingredient where it is, or appends it to its group (the first group,
    /// made now, when the recipe has none).
    private func save(_ ingredient: RecipeIngredient, in groupID: UUID?) {
        if let at = groups.location(of: ingredient.id) {
            groups[at.group].ingredients[at.index] = ingredient
            return
        }
        if groups.isEmpty { groups.append(IngredientGroup()) }
        let g = groups.firstIndex { $0.id == groupID } ?? 0
        withAnimation(DS.Motion.layout) { groups[g].ingredients.append(ingredient) }
    }

    private func remove(_ ingredient: RecipeIngredient) {
        for g in groups.indices {
            groups[g].ingredients.removeAll { $0.id == ingredient.id }
        }
    }
}

/// The ingredient open in the editor sheet and the group it goes in.
private struct EditingIngredient: Identifiable {
    let groupID: UUID?
    let ingredient: RecipeIngredient
    var id: UUID { ingredient.id }
}
