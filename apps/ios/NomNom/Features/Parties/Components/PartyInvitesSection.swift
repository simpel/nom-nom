import SwiftUI

/// The invites a party (or the household) has sent: `DSSection("Invited")` over a
/// `Card(layout: .list)` of PartyInviteRows (ListRow README, Invite shape). Draws
/// nothing when there are none.
struct PartyInvitesSection: View {
    let invites: [PartyInvite]

    var body: some View {
        if !invites.isEmpty {
            DSSection("Invited") {
                Card(layout: .list) {
                    ForEach(invites) { PartyInviteRow(invite: $0) }
                }
            }
        }
    }
}
