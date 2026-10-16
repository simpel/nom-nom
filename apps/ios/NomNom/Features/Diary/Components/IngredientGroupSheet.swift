import SwiftUI

/// Sheet for naming a new ingredient group ("Sauce", "Salad") or renaming one. The
/// name is optional; an existing group can be moved among the others ("Position") or
/// removed together with its ingredients.
struct IngredientGroupSheet: View {
    var isNew: Bool
    var groupCount: Int
    var onSave: (IngredientGroupForm) -> Void
    var onRemove: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var session: FormSession<IngredientGroupForm>

    init(
        group: IngredientGroup,
        position: Int,
        groupCount: Int,
        isNew: Bool,
        onSave: @escaping (IngredientGroupForm) -> Void,
        onRemove: (() -> Void)? = nil
    ) {
        self.isNew = isNew
        self.groupCount = groupCount
        self.onSave = onSave
        self.onRemove = onRemove
        let form = IngredientGroupForm(group: group, position: position)
        self._session = State(initialValue: FormSession(form, kind: isNew ? .create : .edit))
    }

    var body: some View {
        NavigationStack {
            SheetBody {
                Input("Group name (e.g. Sauce)", text: $session.form.group.name)
                    .textInputAutocapitalization(.sentences)

                if !isNew, groupCount > 1 {
                    Card(layout: .list) {
                        SelectRow(
                            "Position",
                            selection: $session.form.position,
                            options: (0..<groupCount).map { SelectRowOption($0, "\($0 + 1) of \(groupCount)") }
                        )
                    }
                }

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
