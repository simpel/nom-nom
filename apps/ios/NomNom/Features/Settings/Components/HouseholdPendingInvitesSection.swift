import SwiftUI

/// Section in Settings listing pending household invitations with resend and revoke.
struct HouseholdPendingInvitesSection: View {
    let pendingInvites: [PartyInvite]

    @Environment(FoodStore.self) private var store

    var body: some View {
        if !pendingInvites.isEmpty {
            DSSection("Pending invitations") {
                Card(layout: .list) {
                    ForEach(pendingInvites) { invite in
                        PendingInviteRow(invite: invite, store: store)
                    }
                }
            }
        }
    }
}
