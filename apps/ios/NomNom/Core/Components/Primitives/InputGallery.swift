import SwiftUI

// Previews for Input and TextArea: every state the README lists.

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
                TextArea("Describe your dinner party\u{2026}", text: $empty)
                TextArea("Add any adjustments\u{2026}", label: "Notes", text: $notes, maxLength: 40)
                TextArea("Error", text: $notes, error: "Keep it under a paragraph.")
                TextArea("Read-only", text: $notes, readOnly: true)
                TextArea("Disabled", text: $notes, disabled: true)
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}

#Preview("Light") { InputGallery() }
#Preview("Dark") { InputGallery().preferredColorScheme(.dark) }
