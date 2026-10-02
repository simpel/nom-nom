import SwiftUI

/// The dinner parties a person belongs to: ListRows (party Avatar, name, their average
/// score) that open the party, or an EmptyState when there are none.
struct ProfilePartiesSection: View {
    let parties: [Party]
    let raterRef: RaterRef

    @Environment(FoodStore.self) private var store

    var body: some View {
        DSSection("Dinner parties", trailing: "\(parties.count)") {
            if parties.isEmpty {
                EmptyState("No dinner parties yet", message: "Parties this person joins will show up here.")
            } else {
                Card(layout: .list) {
                    ForEach(parties) { party in
                        NavigationLink {
                            PartyDetailView(partyID: party.id)
                        } label: {
                            ListRow(
                                party.name,
                                leading: .avatar(Avatar(party: party, size: .sm, decorative: true)),
                                trailing: .score(store.partyAverageScore(partyID: party.id, for: raterRef, limit: 20)?.score),
                                chevron: true
                            )
                        }
                        .buttonStyle(ListRowButtonStyle())
                    }
                }
            }
        }
    }
}

#Preview {
    NomNomPreview { store in
        ProfilePartiesSection(
            parties: store.parties,
            raterRef: .account(store.userID)
        )
        .padding(DS.Spacing.gutter)
    }
}
