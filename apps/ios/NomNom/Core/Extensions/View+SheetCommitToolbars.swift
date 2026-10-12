import SwiftUI

// Implementations behind the session toolbars in `View+SheetToolbars.swift`. They read
// the session for state and the `.editorSheet` above them for closing.

/// Commit sheets and last steps: close (root only) and a checkmark, or a text action,
/// that becomes a spinner while saving.
struct SessionCommitToolbarModifier<Form: SheetForm>: ViewModifier {
    @Environment(\.editorSheetActions) private var editorSheet

    let session: FormSession<Form>
    let title: String?
    let showsClose: Bool
    let save: (Form) async throws -> Void

    func body(content: Content) -> some View {
        content
            .toolbar {
                if showsClose {
                    SheetLeadingCloseItem(accessibilityLabel: "Cancel", isDisabled: session.isSaving) {
                        editorSheet?.close()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if session.isSaving {
                        ProgressView().controlSize(.small)
                    } else if let title {
                        Button(title, action: commit)
                            .disabled(!session.canCommit)
                            .fontWeight(.semibold)
                            .barItemStyle()
                    } else {
                        Button(action: commit) {
                            Image(systemName: "checkmark").fontWeight(.semibold)
                        }
                        .disabled(!session.canCommit)
                        .accessibilityLabel("Save")
                        .barItemStyle()
                    }
                }
            }
            .onAppear { assertEditorSheet(editorSheet) }
    }

    private func commit() {
        guard session.canCommit else { return }
        if session.commitOnlyCloses {
            editorSheet?.finish()
            return
        }
        Task {
            if await session.save(save) { editorSheet?.finish() }
        }
    }
}

/// The first step of a flow: close (asks first when changed) and "Next".
struct SessionNextToolbarModifier<Form: SheetForm>: ViewModifier {
    @Environment(\.editorSheetActions) private var editorSheet

    let session: FormSession<Form>
    let title: String
    let canProceed: Bool
    let onNext: () -> Void

    func body(content: Content) -> some View {
        content
            .toolbar {
                SheetLeadingCloseItem(accessibilityLabel: "Cancel", isDisabled: session.isSaving) {
                    editorSheet?.close()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(title, action: onNext)
                        .disabled(!canProceed || !session.isLoaded)
                        .fontWeight(.semibold)
                        .barItemStyle()
                }
            }
            .onAppear { assertEditorSheet(editorSheet) }
    }
}

/// A session toolbar without `.editorSheet` above it would skip the discard guard and
/// the error alert, so a debug build stops as soon as such a sheet opens.
private func assertEditorSheet(_ actions: EditorSheetActions?) {
    #if DEBUG
    if actions == nil {
        assertionFailure("Session sheet toolbars need .editorSheet(session) on the sheet's NavigationStack.")
    }
    #endif
}
