import SwiftUI

/// Section in MealEditorView for date and chef notes.
struct MealEditorDetailsSection: View {
    @Binding var date: Date
    @Binding var notes: String

    var body: some View {
        SectionCard("Details") {
            VStack(spacing: 12) {
                DatePicker("When", selection: $date, displayedComponents: [.date])

                Divider()

                TextField("Chef notes / adjustments", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }
        }
    }
}
