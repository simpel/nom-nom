// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// The formatting bar a bulleted `NoteEditorSheet` docks above the keyboard, as Notes
/// does: a full-width `panel` capsule lifted with `shadow-xs`, holding icon-only
/// `secondary ghost` AppButtons. On the left, a `destructive ghost` trash shows only when
/// there is a saved note to delete (`onDelete`). Then List, which bullets or unbullets the note.
struct NoteFormatBar: View {
    var onDelete: (() -> Void)?
    let onToggleList: () -> Void

    var body: some View {
        HStack(spacing: DS.Spacing.s2) {
            if let onDelete {
                AppButton(icon: "trash", accessibilityLabel: "Delete note", variant: .destructive, appearance: .ghost) {
                    onDelete()
                }
            }
            AppButton(icon: "list.bullet", accessibilityLabel: "Bulleted list", variant: .secondary, appearance: .ghost) {
                onToggleList()
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DS.Spacing.s2)
        .padding(.vertical, DS.Spacing.s1)
        .frame(maxWidth: .infinity)
        .background(Capsule().fill(DS.Color.panel))
        .dsShadow(.xs)
    }
}

#Preview {
    NoteFormatBar {}
        .padding(DS.Spacing.s4)
        .background(DS.Color.sheet)
}
