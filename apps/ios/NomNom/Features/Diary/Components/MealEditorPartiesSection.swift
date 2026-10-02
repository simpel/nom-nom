import SwiftUI

/// The dinner parties a meal is served to: one ListRow Toggle row per party (its
/// Avatar `sm` and name) in a list Card.
struct MealEditorPartiesSection: View {
    @Binding var selectedParties: Set<UUID>

    @Environment(FoodStore.self) private var store

    var body: some View {
        if !store.myParties.isEmpty {
            DSSection("Serve to dinner parties") {
                Card(layout: .list) {
                    ForEach(store.myParties) { party in
                        ListRow(
                            party.name,
                            leading: .avatar(Avatar(party: party, size: .sm, decorative: true)),
                            trailing: .toggle(isServed(party))
                        )
                    }
                }
            }
        }
    }

    private func isServed(_ party: Party) -> Binding<Bool> {
        Binding(
            get: { selectedParties.contains(party.id) },
            set: { isSelected in
                if isSelected {
                    selectedParties.insert(party.id)
                } else {
                    selectedParties.remove(party.id)
                }
            }
        )
    }
}
