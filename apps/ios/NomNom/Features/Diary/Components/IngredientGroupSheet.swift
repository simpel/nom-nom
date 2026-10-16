import SwiftUI

/// Sheet for naming a new ingredient group ("Sauce", "Salad") or renaming one. The
/// name is optional; an existing group can be removed together with its ingredients.
struct IngredientGroupSheet: View {
    var isNew: Bool
    var onSave: (IngredientGroup) -> Void
    var onRemove: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var session: FormSession<IngredientGroup>

    init(group: IngredientGroup, isNew: Bool, onSave: @escaping (IngredientGroup) -> Void, onRemove: (() -> Void)? = nil) {
        self.isNew = isNew
        self.onSave = onSave
        self.onRemove = onRemove
        self._session = State(initialValue: FormSession(group, kind: isNew ? .create : .edit))
    }

    var body: some View {
        NavigationStack {
            SheetBody {
                Input("Group name (e.g. Sauce)", text: $session.form.name)
                    .textInputAutocapitalization(.sentences)

                if !isNew {
                    AppButton(
                        "Remove Group",
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
            .screenTitle(isNew ? "Add Group" : "Edit Group", displayMode: .inline)
            .sheetCommitToolbar(session) { onSave($0) }
        }
        .editorSheet(session, detents: [.medium])
    }
}
