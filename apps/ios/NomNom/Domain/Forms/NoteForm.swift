import Foundation

/// One multi-line note in NoteEditorSheet. A bulleted note opens on a bullet; a lone
/// bullet with nothing after it saves as empty.
struct NoteForm: SheetForm {
    var text: String
    var maxLength: Int?

    var isValid: Bool { maxLength.map { text.count <= $0 } ?? true }
}

extension NoteForm {
    init(_ text: String, maxLength: Int?, bulleted: Bool) {
        self.text = bulleted && text.isEmpty ? BulletList.marker : text
        self.maxLength = maxLength
    }

    /// The text as saved.
    var committed: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed == BulletList.marker.trimmingCharacters(in: .whitespaces) ? "" : text
    }
}
