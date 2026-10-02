import SwiftUI

/// Section in MealEditorView for date and chef notes, presented as two distinct cards
/// `spacing-7` (`block`) apart.
struct MealEditorDetailsSection: View {
    @Binding var date: Date
    @Binding var notes: String

    var body: some View {
        VStack(spacing: DS.Spacing.block) {
            SectionCard("Date") {
                DatePicker("Date eaten", selection: $date, displayedComponents: [.date])
                    .textStyle(.sansMd)
            }

            SectionCard("Notes", trailing: "Optional") {
                TextArea("Add any adjustments, substitutions, or memories...", text: $notes, lineLimit: 3...6)
            }
        }
    }
}
