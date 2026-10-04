import SwiftUI

// Previews for Input, TextArea and NoteField. Forms use NoteField; TextArea is the
// editor inside NoteEditorSheet.

private struct InputGallery: View {
    @State private var name = "Carbonara"
    @State private var empty = ""
    @State private var notes = "Made extra crispy with homemade salsa verde."

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s4) {
                Input("Search recipes", text: $empty, leadingIcon: "magnifyingglass")
                Input("Recipe name", text: $name, clearable: true, hint: "Shown on the recipe card.")
                Input("Email", label: "Email", text: $empty, appearance: .soft)
                Input("Email", text: $name, error: "That address is missing a domain.")
                Input("Quantity", text: $name, isError: true)
                Input("Household", label: "Household", text: $name, readOnly: true)
                Input("Disabled", text: $name, disabled: true)
                Card(layout: .list) { Input(label: "First name", placeholder: "Anna", text: $empty, appearance: .plain) }
                SectionCard("Notes") {
                    NoteField("Add any adjustments\u{2026}", text: $empty, title: "Notes")
                }
                SectionCard("Notes") {
                    NoteField("Add any adjustments\u{2026}", text: $notes, title: "Notes", maxLength: 40)
                }
                TextArea("Add any adjustments\u{2026}", label: "Notes", text: $notes, maxLength: 40)
                TextArea("Error", text: $notes, error: "Keep it under a paragraph.")
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}

#Preview("Light") { InputGallery() }
#Preview("Dark") { InputGallery().preferredColorScheme(.dark) }
