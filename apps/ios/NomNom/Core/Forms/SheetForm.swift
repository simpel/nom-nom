import Foundation

/// The value an edit sheet works on. Equatable so its `FormSession` can tell whether it
/// changed; `isValid` says whether it can be committed (required fields filled).
/// Each editable thing has one form type in `Domain/Forms/`, shared by every sheet that
/// edits it (AGENTS.md §5, "Editor model").
protocol SheetForm: Equatable {
    var isValid: Bool { get }
}

extension SheetForm {
    var isValid: Bool { true }
}
