import SwiftUI

/// Sheet for adding or editing a single recipe ingredient.
struct IngredientEditorSheet: View {
    let initialIngredient: RecipeIngredient
    var isNew: Bool
    var onSave: (RecipeIngredient) -> Void
    var onRemove: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var draft: RecipeIngredient

    init(initialIngredient: RecipeIngredient, isNew: Bool, onSave: @escaping (RecipeIngredient) -> Void, onRemove: (() -> Void)? = nil) {
        self.initialIngredient = initialIngredient
        self.isNew = isNew
        self.onSave = onSave
        self.onRemove = onRemove
        self._draft = State(initialValue: initialIngredient)
    }

    var body: some View {
        NavigationStack {
            SheetBody {
                Input("Ingredient name", text: $draft.ingredient)
                    .textInputAutocapitalization(.words)

                HStack(spacing: DS.Spacing.s3) {
                    Input("Qty", text: $draft.quantity)
                        .keyboardType(.numbersAndPunctuation)

                    Input("Unit (e.g. tbsp)", text: $draft.measurement)
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
            .sheetCommitToolbar(isSaving: false, canSave: !draft.trimmedIngredient.isEmpty, onCancel: { dismiss() }) {
                onSave(draft)
                dismiss()
            }
        }
        .dsSheet(detents: [.medium, .large])
    }
}
