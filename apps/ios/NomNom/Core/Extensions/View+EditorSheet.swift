import SwiftUI

// The root of every edit sheet (AGENTS.md §5): the BottomSheet presentation plus
// Mail-style dismissal. An untouched sheet swipes and closes freely; a changed one asks
// "Discard changes?" on swipe or close; a saving one can't be dismissed at all.

/// What the sheet chrome inside an editor sheet calls to close it. Set by
/// `.editorSheet` / `.discardGuard`; the sheet toolbars read it from the environment.
struct EditorSheetActions {
    /// While true, nothing closes the sheet (the close button is disabled).
    let isSaving: Bool
    /// Closes the sheet, asking "Discard changes?" first when it has changes.
    let close: () -> Void
    /// Closes the sheet without asking (after a successful save).
    let finish: () -> Void
}

extension EnvironmentValues {
    /// Dismisses the whole sheet from any pushed step. Set by `.editorSheet`.
    @Entry var dismissSheet: DismissAction? = nil
    @Entry var editorSheetActions: EditorSheetActions? = nil
}

extension View {
    /// The root of every edit sheet. Apply to the NavigationStack in place of `.dsSheet()`.
    /// Adds the BottomSheet presentation, Mail-style dismissal (from `isDirty` /
    /// `isSaving`), the error alert, and `\.dismissSheet` for pushed steps.
    func editorSheet<Form: SheetForm>(
        _ session: FormSession<Form>,
        detents: Set<PresentationDetent> = [.large],
        errorTitle: String = "Couldn\u{2019}t save",
        onDiscard: (() -> Void)? = nil
    ) -> some View {
        modifier(EditorSheetModifier(session: session, errorTitle: errorTitle, onDiscard: onDiscard))
            .dsSheet(detents: detents)
    }

    /// The Mail-style dismissal on its own, for a sheet whose state is not a form (the
    /// recipe scanner's staged photos). Apply to the NavigationStack, next to `.dsSheet()`.
    /// Edit sheets use `.editorSheet` instead.
    func discardGuard(isDirty: Bool, isSaving: Bool, onDiscard: @escaping () -> Void = {}) -> some View {
        modifier(DiscardGuard(isDirty: isDirty, isSaving: isSaving, onDiscard: onDiscard))
    }
}

private struct EditorSheetModifier<Form: SheetForm>: ViewModifier {
    let session: FormSession<Form>
    let errorTitle: String
    let onDiscard: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .discardGuard(isDirty: session.isDirty, isSaving: session.isSaving) {
                onDiscard?()
                session.discard()
            }
            .alert(errorTitle, isPresented: Binding(
                get: { session.error != nil },
                set: { if !$0 { session.error = nil } }
            )) {
                Button("OK") { session.error = nil }
            } message: {
                Text(session.error ?? "")
            }
    }
}

private struct DiscardGuard: ViewModifier {
    let isDirty: Bool
    let isSaving: Bool
    let onDiscard: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingDiscard = false

    func body(content: Content) -> some View {
        content
            .environment(\.dismissSheet, dismiss)
            .environment(\.editorSheetActions, EditorSheetActions(
                isSaving: isSaving,
                close: close,
                finish: { dismiss() }
            ))
            .interactiveDismissDisabled(isDirty || isSaving)
            .background(SheetDismissAttemptObserver { if isDirty && !isSaving { isConfirmingDiscard = true } })
            .confirmationDialog("Discard changes?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
                Button("Discard changes", role: .destructive) {
                    onDiscard()
                    dismiss()
                }
                Button("Keep editing", role: .cancel) {}
            }
    }

    private func close() {
        guard !isSaving else { return }
        if isDirty { isConfirmingDiscard = true } else { dismiss() }
    }
}

// MARK: - Preview

private struct EditorSheetPreviewForm: SheetForm {
    var name = "Taco Night"
    var isValid: Bool { !name.trimmedName.isEmpty }
}

/// Change the name to see the prompt on swipe and close; save "fail" to see the error.
private struct EditorSheetPreview: View {
    @State private var isPresented = true
    @State private var session = FormSession(EditorSheetPreviewForm())

    var body: some View {
        Color.clear
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    SheetBody {
                        SectionCard("Party Name") {
                            Input("Party name", text: $session.form.name, appearance: .plain)
                        }
                    }
                    .screenTitle("Edit party", displayMode: .inline)
                    .sheetCommitToolbar(session) { form in
                        try await Task.sleep(for: .seconds(DS.Motion.durationLayout))
                        if form.name == "fail" { throw StoreError(errorDescription: "The server rejected those values.") }
                    }
                }
                .editorSheet(session)
            }
    }
}

#Preview("Light") { NomNomPreview(inNavigationStack: false) { EditorSheetPreview() } }
#Preview("Dark") { NomNomPreview(inNavigationStack: false) { EditorSheetPreview() }.preferredColorScheme(.dark) }
