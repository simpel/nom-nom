import SwiftUI

/// Section in MealEditorView managing party assignments and party creation trigger.
struct MealEditorPartiesSection: View {
    @Binding var selectedParties: Set<UUID>
    let onCreateParty: () -> Void

    @Environment(FoodStore.self) private var store

    var body: some View {
        SectionCard("Serve to Dinner Parties") {
            VStack(spacing: 12) {
                ForEach(store.myParties) { party in
                    Toggle(isOn: Binding(
                        get: { selectedParties.contains(party.id) },
                        set: { isSelected in
                            if isSelected {
                                selectedParties.insert(party.id)
                            } else {
                                selectedParties.remove(party.id)
                            }
                        }
                    )) {
                        Label(party.name, systemImage: "person.2.fill")
                    }

                    Divider()
                }

                Button(action: onCreateParty) {
                    Label("Create new party...", systemImage: "plus")
                        .font(.inter(.subheadline, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .padding(.top, 2)
            }
        }
    }
}
