// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// A multi-line note in a form, edited the way Apple Maps edits "Add a Note": the row
/// shows the note as the cook's note (`serif-xs` italic, like SectionCard's `quote`) or
/// a `sans-md` `text-tertiary` placeholder, with no chevron; tapping it opens a full-height
/// `NoteEditorSheet`. Replaces an inline TextArea in every form. No ground or border:
/// it sits in its host card like a ListRow.
struct NoteField: View {
    let placeholder: String
    @Binding var text: String
    let title: String
    var maxLength: Int?

    @State private var isEditing = false

    init(_ placeholder: String, text: Binding<String>, title: String, maxLength: Int? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.title = title
        self.maxLength = maxLength
    }

    private var isEmpty: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        Button {
            isEditing = true
        } label: {
            Group {
                if isEmpty {
                    Text(placeholder)
                        .textStyle(.sansMd, tone: .tertiary, lines: 3)
                } else {
                    Text(text)
                        .textStyle(.serifXs, italic: true, lines: 3)
                }
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: DS.Spacing.s14, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(AppPressableButtonStyle())
        .accessibilityLabel(title)
        .accessibilityValue(isEmpty ? "Empty" : text)
        .accessibilityHint("Opens the editor")
        .sheet(isPresented: $isEditing) {
            NoteEditorSheet(title: title, placeholder: placeholder, text: $text, maxLength: maxLength)
        }
    }
}

private struct NoteFieldPreview: View {
    @State private var empty = ""
    @State private var filled = "The kids picked out the peas. Less mint next time, and double the lemon."

    var body: some View {
        NomNomPreview(inNavigationStack: false) { _ in
            VStack(spacing: DS.Spacing.block) {
                SectionCard("Notes", trailing: "Optional") {
                    NoteField("Add any adjustments, substitutions, or memories…", text: $empty, title: "Notes")
                }
                SectionCard("Notes & Review") {
                    NoteField("Add your thoughts…", text: $filled, title: "Notes & review")
                }
            }
            .padding(DS.Spacing.gutter)
        }
    }
}

#Preview { NoteFieldPreview() }
