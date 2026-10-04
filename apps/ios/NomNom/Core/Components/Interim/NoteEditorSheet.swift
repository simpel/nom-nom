// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// The full edit mode a `NoteField` opens, modelled on Apple Maps' "Add a Note": an
/// inline title, close (discards the draft) and checkmark (commits), one `panel` card
/// filling the sheet with the keyboard already up, and "Delete note" when there was
/// text to begin with. The inline title is the header, so there is no ScreenHeader
/// (DS-GAPS B: note editor anatomy).
struct NoteEditorSheet: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var maxLength: Int?

    @Environment(\.dismiss) private var dismiss
    @State private var draft: String
    @FocusState private var isFocused: Bool

    init(title: String, placeholder: String, text: Binding<String>, maxLength: Int? = nil) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.maxLength = maxLength
        self._draft = State(initialValue: text.wrappedValue)
    }

    private var hadText: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
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

                if hadText {
                    AppButton(
                        "Delete note",
                        icon: "trash",
                        variant: .destructive,
                        appearance: .soft,
                        size: .lg,
                        fullWidth: true
                    ) {
                        text = ""
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s2)
            .padding(.bottom, DS.Spacing.s4)
            .background(DS.Color.sheet)
            .screenTitle(title, displayMode: .inline)
            .sheetCommitToolbar(canSave: draft != text && !isOver) {
                text = draft
                dismiss()
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
