import SwiftUI

/// Invitations to join dinner parties: a DSSection over a `Card(layout: .list)` of
/// ListRows (Subject shape): the party's Avatar, its name, "Invited by …", then Accept
/// (`primary solid sm`) and Decline (`secondary soft sm`) — ListRow README: "two
/// labelled buttons … Never an unlabelled ✕ in a row".
struct PendingPartyInvitesSection: View {
    @Environment(FoodStore.self) private var store

    var body: some View {
        if !store.pendingPartyInvites.isEmpty {
            DSSection("Pending invitations", trailing: "\(store.pendingPartyInvites.count)", trailingTone: .primary) {
                Card(layout: .list) {
                    ForEach(store.pendingPartyInvites) { invite in
                        row(invite)
                    }
                }
            }
        }
    }

    private func row(_ invite: PartyInvite) -> some View {
        let party = store.party(invite.partyID)
        let name = party?.name ?? "Dinner Party"
        let inviter = store.label(for: .account(invite.inviterID))
        return ListRow(
            name,
            meta: "Invited by \(inviter.name)",
            leading: .avatar(party.map { Avatar(party: $0, size: .sm, decorative: true) }
                ?? Avatar(name: name, size: .sm, decorative: true)),
            trailing: .view {
                HStack(spacing: DS.Spacing.s2) {
                    AppButton("Accept", size: .sm) {
                        Task { await store.acceptPartyInvite(invite) }
                    }
                    AppButton("Decline", variant: .secondary, appearance: .soft, size: .sm) {
                        Task { await store.declinePartyInvite(invite) }
                    }
                    .accessibilityLabel("Decline invite to \(name)")
                }
            }
        )
    }
}

#Preview {
    NomNomPreview { _ in
        PendingPartyInvitesSection()
            .padding(DS.Spacing.gutter)
    }
}
