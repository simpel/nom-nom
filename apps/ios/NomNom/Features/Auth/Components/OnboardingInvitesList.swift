import SwiftUI

/// The invites in onboarding's party step: parties already joined first (a "Joined"
/// Badge), then pending invites as ListRows with Accept (`primary solid sm`) and
/// Decline (`secondary soft sm`), as PendingPartyInvitesSection draws them. With
/// neither, an EmptyState card points at the code field below.
struct OnboardingInvitesList: View {
    @Environment(FoodStore.self) private var store

    let joinedPartyIDs: [UUID]
    var busyInviteID: UUID?
    let onAccept: (PartyInvite) -> Void
    let onDecline: (PartyInvite) -> Void

    private var joined: [Party] { joinedPartyIDs.compactMap { store.party($0) } }
    private var pending: [PartyInvite] { store.pendingPartyInvites }

    var body: some View {
        if joined.isEmpty && pending.isEmpty {
            EmptyState(
                "No invitations yet",
                message: "Add the code someone sent you, or start your own party.",
                layout: .card
            )
        } else {
            Card(layout: .list) {
                ForEach(joined) { party in
                    ListRow(
                        party.name,
                        leading: .avatar(Avatar(party: party, size: .sm, decorative: true)),
                        trailing: .badge(Badge("Joined", size: .sm))
                    )
                }
                ForEach(pending) { invite in
                    row(invite)
                }
            }
        }
    }

    private func row(_ invite: PartyInvite) -> some View {
        let party = store.party(invite.partyID)
        let name = party?.name ?? "Dinner Party"
        let inviter = store.label(for: .account(invite.inviterID))
        let isBusy = busyInviteID == invite.id
        return ListRow(
            name,
            meta: "Invited by \(inviter.name)",
            leading: .avatar(party.map { Avatar(party: $0, size: .sm, decorative: true) }
                ?? Avatar(name: name, size: .sm, decorative: true)),
            trailing: .view {
                HStack(spacing: DS.Spacing.s2) {
                    AppButton("Accept", size: .sm, isLoading: isBusy) { onAccept(invite) }
                    AppButton("Decline", variant: .secondary, appearance: .soft, size: .sm) { onDecline(invite) }
                        .accessibilityLabel("Decline invite to \(name)")
                }
                .disabled(busyInviteID != nil)
            }
        )
    }
}
