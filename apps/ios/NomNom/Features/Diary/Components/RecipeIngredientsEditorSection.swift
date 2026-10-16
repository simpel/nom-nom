import SwiftUI

/// The ingredients in a recipe editor, in their groups ("Sauce", "Salad"). A recipe
/// without groups is one "Ingredients" section; once a group is added each group is its
/// own section, titled by its name, with "Rename" on the header. Rows edit in
/// IngredientEditorSheet, groups in IngredientGroupSheet.
struct RecipeIngredientsEditorSection: View {
    @Binding var groups: [IngredientGroup]

    @State private var editingIngredient: EditingIngredient?
    @State private var editingGroup: IngredientGroup?
    @State private var openRowID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.block) {
            if groups.isUngrouped {
                DSSection("Ingredients") { card(for: groups.first) }
            } else {
                ForEach(groups) { group in
                    DSSection(
                        group.title ?? "Ingredients",
                        action: SectionAction("Rename", accessibilityLabel: "Rename \(group.title ?? "group")") { editingGroup = group }
                    ) {
                        card(for: group)
                    }
                }
            }

            AppButton("Add Group", icon: "plus", variant: .secondary, appearance: .ghost, size: .sm) {
                editingGroup = IngredientGroup()
            }
        }
        .sheet(item: $editingIngredient) { editing in
            IngredientEditorSheet(
                initialIngredient: editing.ingredient,
                isNew: !groups.allIngredients.contains { $0.id == editing.id },
                onSave: { save($0, in: editing.groupID) },
                onRemove: { remove(editing.ingredient) }
            )
        }
        .sheet(item: $editingGroup) { group in
            IngredientGroupSheet(
                group: group,
                isNew: !groups.contains { $0.id == group.id },
                onSave: save(_:),
                onRemove: { withAnimation(DS.Motion.layout) { groups.removeAll { $0.id == group.id } } }
            )
        }
    }

    private func card(for group: IngredientGroup?) -> some View {
        IngredientGroupEditorCard(
            ingredients: group?.ingredients ?? [],
            openRowID: $openRowID,
            onEdit: { editingIngredient = EditingIngredient(groupID: group?.id, ingredient: $0) },
            onRemove: { item in withAnimation(DS.Motion.layout) { remove(item) } },
            onAdd: { editingIngredient = EditingIngredient(groupID: group?.id, ingredient: RecipeIngredient()) }
        )
    }

    /// Updates the ingredient where it is, or appends it to its group (the first group,
    /// made now, when the recipe has none).
    private func save(_ ingredient: RecipeIngredient, in groupID: UUID?) {
        for g in groups.indices {
            if let i = groups[g].ingredients.firstIndex(where: { $0.id == ingredient.id }) {
                groups[g].ingredients[i] = ingredient
                return
            }
        }
        if groups.isEmpty { groups.append(IngredientGroup()) }
        let g = groups.firstIndex { $0.id == groupID } ?? 0
        withAnimation(DS.Motion.layout) { groups[g].ingredients.append(ingredient) }
    }

    private func save(_ group: IngredientGroup) {
        if let g = groups.firstIndex(where: { $0.id == group.id }) {
            groups[g].name = group.name
        } else {
            withAnimation(DS.Motion.layout) { groups.append(group) }
        }
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
