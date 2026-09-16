import SwiftUI

/// Section in MealEditorView for date and chef notes, presented as two distinct cards.
struct MealEditorDetailsSection: View {
    @Binding var date: Date
    @Binding var notes: String

    var body: some View {
        SectionCard("Date") {
            DatePicker("Date eaten", selection: $date, displayedComponents: [.date])
                .font(.body.weight(.medium))
        }

        SectionCard("Notes", caption: "Optional") {
            TextArea("Add any adjustments, substitutions, or memories...", text: $notes, lineLimit: 3...6)
        }
    }
}
