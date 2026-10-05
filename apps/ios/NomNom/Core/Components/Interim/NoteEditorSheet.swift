// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// The full edit mode a `NoteField` opens, modelled on Apple Maps' "Add a Note": an
/// inline title, close (discards the draft) and checkmark (commits), one `panel` card
/// filling the sheet with the keyboard already up, and "Delete note" when there was
/// text to begin with. The inline title is the header, so there is no ScreenHeader
/// (DS-GAPS B: note editor anatomy).
///
/// Every note editor carries the `NoteFormatBar` above the keyboard (bullet list toggle
/// and, when a note is saved, the trash), and Return continues a bullet list
/// (`BulletList`). `bulleted` only makes the note open on a bullet (DS-GAPS A, "NoteField").
struct NoteEditorSheet: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var maxLength: Int?
    var bulleted: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var draft: String
    @State private var confirmDelete = false
    @FocusState private var isFocused: Bool

    init(title: String, placeholder: String, text: Binding<String>, maxLength: Int? = nil, bulleted: Bool = false) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.maxLength = maxLength
        self.bulleted = bulleted
        let start = text.wrappedValue
        self._draft = State(initialValue: bulleted && start.isEmpty ? BulletList.marker : start)
    }

    private var hadText: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    /// The draft as saved: a lone bullet with nothing after it counts as empty.
    private var committed: String {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed == BulletList.marker.trimmingCharacters(in: .whitespaces) ? "" : draft
    }

    private var isOver: Bool { maxLength.map { draft.count > $0 } ?? false }

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.s4) {
                Card {
                    ScrollView {
                        TextArea(
                            placeholder,
                            text: $draft,
                            lineLimit: 1...Int.max,
                            appearance: .plain,
                            maxLength: maxLength,
                            isFocused: $isFocused
                        )
                    }
                    .scrollDismissesKeyboard(.never)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { isFocused = true }

                if isFocused {
                    // Docked above the keyboard, where Notes puts its bar (trash included
                    // when there is a saved note); the full-width Delete note returns
                    // when the keyboard goes down.
                    NoteFormatBar(onDelete: hadText ? { confirmDelete = true } : nil) {
                        draft = BulletList.toggled(draft)
                    }
                } else if hadText {
                    AppButton(
                        "Delete note",
                        icon: "trash",
                        variant: .destructive,
                        appearance: .soft,
                        size: .lg,
                        fullWidth: true
                    ) {
                        confirmDelete = true
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s2)
            .padding(.bottom, DS.Spacing.s4)
            .background(DS.Color.sheet)
            .screenTitle(title, displayMode: .inline)
            .sheetCommitToolbar(canSave: committed != text && !isOver) {
                text = committed
                dismiss()
            }
            .confirmationDialog("Delete this note?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete note", role: .destructive) {
                    text = ""
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("It\u{2019}s removed from the recipe for everyone in the party.")
            }
            .onChange(of: draft) { old, new in
                let continued = BulletList.continuing(old, into: new)
                if continued != new { draft = continued }
            }
        }
        .dsSheet()
        .onAppear { isFocused = true }
    }
}

private struct NoteEditorSheetPreview: View {
    @State private var note = "The kids picked out the peas."

    var body: some View {
        NomNomPreview(inNavigationStack: false) { _ in
            NoteEditorSheet(title: "Notes", placeholder: "Add your thoughts…", text: $note, maxLength: 280)
        }
    }
}

#Preview { NoteEditorSheetPreview() }
