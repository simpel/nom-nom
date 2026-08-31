import SwiftUI

/// A pending invitation to join a dinner party.
struct PendingPartyInviteCard: View {
    let invite: PartyInvite

    @Environment(FoodStore.self) private var store
    @State private var isWorking = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.2.circle.fill")
                .font(.title)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 3) {
                let party = store.party(invite.partyID)
                Text(party?.name ?? "Dinner Party")
                    .font(.body.weight(.medium))
                let inviter = store.label(for: .account(invite.inviterID))
                Text("Invited by \(inviter.emoji) \(inviter.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isWorking {
                ProgressView().controlSize(.small)
            } else {
                Button("Accept") {
                    isWorking = true
                    Task {
                        await store.acceptPartyInvite(invite)
                        isWorking = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("Decline") {
                    isWorking = true
                    Task {
                        await store.declinePartyInvite(invite)
                        isWorking = false
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}
