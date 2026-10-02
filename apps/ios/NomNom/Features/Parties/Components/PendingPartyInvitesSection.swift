import SwiftUI

/// Invitations to join dinner parties: a DSSection over a `Card(layout: .list)` of
/// ListRows (Subject shape): the party's Avatar, its name, "Invited by …", Accept
/// (`primary solid sm`) and a `secondary ghost` ✕ to decline (ListRow README: "One
/// trailing element, or two where the second is a `ghost` icon button").
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
            trailing: .button(AppButton("Accept", size: .sm) {
                Task { await store.acceptPartyInvite(invite) }
            }),
            trailingAction: ListRowIconAction(icon: "xmark", accessibilityLabel: "Decline invite to \(name)", variant: .secondary) {
                Task { await store.declinePartyInvite(invite) }
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
