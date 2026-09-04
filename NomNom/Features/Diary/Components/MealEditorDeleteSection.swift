import SwiftUI

/// Section in MealEditorView displaying the delete action button.
struct MealEditorDeleteSection: View {
    let isSaving: Bool
    let onDelete: () -> Void

    @State private var showingConfirmation = false

    var body: some View {
        SectionCard {
            Button(role: .destructive) {
                showingConfirmation = true
            } label: {
                Label("Delete this meal", systemImage: "trash")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
        }
        .confirmationDialog(
            "Delete this meal?",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Meal", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove this meal log.")
        }
    }
}

#Preview {
    MealEditorDeleteSection(
        isSaving: false,
        onDelete: {}
    )
    .padding()
    .background(DS.Color.bg)
}
