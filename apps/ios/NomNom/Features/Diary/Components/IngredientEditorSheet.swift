import SwiftUI

/// Sheet for adding or editing a single recipe ingredient.
struct IngredientEditorSheet: View {
    let initialIngredient: RecipeIngredient
    var isNew: Bool
    var onSave: (RecipeIngredient) -> Void
    var onRemove: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var session: FormSession<RecipeIngredient>

    init(initialIngredient: RecipeIngredient, isNew: Bool, onSave: @escaping (RecipeIngredient) -> Void, onRemove: (() -> Void)? = nil) {
        self.initialIngredient = initialIngredient
        self.isNew = isNew
        self.onSave = onSave
        self.onRemove = onRemove
        self._session = State(initialValue: FormSession(initialIngredient, kind: isNew ? .create : .edit))
    }

    var body: some View {
        NavigationStack {
            SheetBody {
                Input("Ingredient name", text: $session.form.ingredient)
                    .textInputAutocapitalization(.words)

                HStack(spacing: DS.Spacing.s3) {
                    Input("Qty", text: $session.form.quantity)
                        .keyboardType(.numbersAndPunctuation)

                    Input("Unit (e.g. tbsp)", text: $session.form.measurement)
                        .textInputAutocapitalization(.never)
                }

                if !isNew {
                    AppButton(
                        "Remove Ingredient",
                        icon: "trash",
                        variant: .destructive,
                        appearance: .outline,
                        fullWidth: true
                    ) {
                        onRemove?()
                        dismiss()
                    }
                    .padding(.top, DS.Spacing.s3)
                }
            }
            .screenTitle(isNew ? "Add Ingredient" : "Edit Ingredient", displayMode: .inline)
            .sheetCommitToolbar(session) { onSave($0) }
        }
        .editorSheet(session, detents: [.medium, .large])
    }
}
