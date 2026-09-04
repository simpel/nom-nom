import SwiftUI

/// Section in MealEditorView managing party assignments.
struct MealEditorPartiesSection: View {
    @Binding var selectedParties: Set<UUID>

    @Environment(FoodStore.self) private var store

    var body: some View {
        if !store.myParties.isEmpty {
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
                            HStack(spacing: 10) {
                                PartyAvatar(party: party, size: 28)
                                Text(party.name)
                                    .font(.body)
                                    .foregroundStyle(DS.Color.textPrimary)
                            }
                        }

                        if party.id != store.myParties.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}
