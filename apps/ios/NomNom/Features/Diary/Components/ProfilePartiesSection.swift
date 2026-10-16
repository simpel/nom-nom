import SwiftUI

/// The dinner parties a person belongs to: ListRows (party Avatar, name, their average
/// score) that open the party. On your own profile the section offers "New party" (the
/// header, or the empty state while there are none); on someone else's it has no button.
struct ProfilePartiesSection: View {
    let parties: [Party]
    let raterRef: RaterRef
    /// `nil` on someone else's profile.
    var onCreate: (() -> Void)?

    @Environment(FoodStore.self) private var store

    var body: some View {
        CollectionSection(
            "Dinner parties",
            count: parties.count,
            verb: "New party",
            addLabel: "New dinner party",
            onAdd: onCreate,
            emptyTitle: "No dinner parties yet",
            emptyMessage: onCreate == nil
                ? "Parties this person joins will show up here."
                : "Start a party or join one with an invite."
        ) {
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

#Preview {
    NomNomPreview { store in
        ProfilePartiesSection(
            parties: store.parties,
            raterRef: .account(store.userID),
            onCreate: {}
        )
        .padding(DS.Spacing.gutter)
    }
}
