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
    var onRemove: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var session: FormSession<NoteForm>
    @State private var confirmDelete = false
    @FocusState private var isFocused: Bool

    init(title: String, placeholder: String, text: Binding<String>, maxLength: Int? = nil, bulleted: Bool = false, onRemove: (() -> Void)? = nil) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.maxLength = maxLength
        self.bulleted = bulleted
        self.onRemove = onRemove
        let form = NoteForm(text.wrappedValue, maxLength: maxLength, bulleted: bulleted)
        self._session = State(initialValue: FormSession(form))
    }

    private var hadText: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var canDelete: Bool { hadText || onRemove != nil }

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.s4) {
                Card {
                    ScrollView {
                        TextArea(
                            placeholder,
                            text: $session.form.text,
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
                    NoteFormatBar(onDelete: canDelete ? { confirmDelete = true } : nil) {
                        session.form.text = BulletList.toggled(session.form.text)
                    }
                } else if canDelete {
                    AppButton(
                        onRemove != nil ? "Remove" : "Delete note",
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
            .sheetCommitToolbar(session) { text = $0.committed }
            .alert(onRemove != nil ? "Remove this?" : "Delete this note?", isPresented: $confirmDelete) {
                Button(onRemove != nil ? "Remove" : "Delete note", role: .destructive) {
                    if let onRemove {
                        onRemove()
                    } else {
                        text = ""
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if onRemove == nil {
                    Text("It\u{2019}s removed from the recipe for everyone in the party.")
                }
            }
            .onChange(of: session.form.text) { old, new in
                let continued = BulletList.continuing(old, into: new)
                if continued != new { session.form.text = continued }
            }
        }
        .editorSheet(session)
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
