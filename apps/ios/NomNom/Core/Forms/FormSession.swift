import Observation
import UIKit

/// One edit sheet's lifecycle: the form, the value it opened with, saving and errors.
/// Owned by the sheet root as `@State`; pushed steps get it (or `$session.form`) passed in.
/// Put `.editorSheet(session)` on the sheet's NavigationStack and use the session
/// toolbars (`.sheetCommitToolbar(session)`, `.sheetNextToolbar(session, …)`,
/// `.stepCommitToolbar(session)`); they read everything else from here.
@MainActor @Observable
final class FormSession<Form: SheetForm> {
    /// `.create` always commits; `.edit` closes without saving when nothing changed.
    enum Kind { case create, edit }

    let kind: Kind
    var form: Form
    private(set) var baseline: Form
    private(set) var isLoaded: Bool
    private(set) var isSaving = false
    var error: String?

    /// Pass `isLoaded: false` when the opening value comes later (from the store, or
    /// prefills); then call `load(_:)` once it is known.
    init(_ form: Form, kind: Kind = .edit, isLoaded: Bool = true) {
        self.kind = kind
        self.form = form
        self.baseline = form
        self.isLoaded = isLoaded
    }

    /// Changed since the sheet opened (or since `load`). Drives Mail-style dismissal.
    var isDirty: Bool { form != baseline }

    /// Whether the checkmark only closes the sheet: an edit with nothing changed.
    var commitOnlyCloses: Bool { kind == .edit && !isDirty }

    /// The checkmark is always active (decision 7 Oct 2026): an unchanged edit just
    /// closes, like the xmark; anything else saves. It is disabled only while loading or
    /// saving, or when the form it would save is invalid (e.g. the name was cleared).
    var canCommit: Bool { isLoaded && !isSaving && (commitOnlyCloses || form.isValid) }

    /// Sets the opening value once, after async loads and prefills. Later calls are ignored.
    func load(_ form: Form) {
        guard !isLoaded else { return }
        self.form = form
        baseline = form
        isLoaded = true
    }

    /// Puts the form back to the opening value.
    func discard() {
        form = baseline
    }

    /// Runs `commit` with the save haptics (medium impact, then success), keeps `isSaving`
    /// set while it runs, and puts a failure's message in `error`. Returns true on success.
    func save(_ commit: (Form) async throws -> Void) async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        defer { isSaving = false }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        do {
            try await commit(form)
            baseline = form
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return true
        } catch {
            self.error = (error as? StoreError)?.errorDescription ?? FoodStore.describe(error)
            return false
        }
    }
}
