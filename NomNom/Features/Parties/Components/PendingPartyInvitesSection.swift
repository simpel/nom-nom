import SwiftUI

/// Section displaying pending invitations to join dinner parties.
struct PendingPartyInvitesSection: View {
    @Environment(FoodStore.self) private var store

    var body: some View {
        if !store.pendingPartyInvites.isEmpty {
            SectionCard("Pending Invitations") {
                VStack(spacing: 12) {
                    ForEach(store.pendingPartyInvites) { invite in
                        let party = store.party(invite.partyID)
                        HStack(spacing: 12) {
                            if let party {
                                PartyAvatar(party: party, size: 40)
                            } else {
                                PartyAvatar(name: "Dinner Party", size: 40)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(party?.name ?? "Dinner Party")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(DS.Color.textPrimary)

                                let inviter = store.label(for: .account(invite.inviterID))
                                Text("Invited by \(inviter.name)")
                                    .font(.caption)
                                    .foregroundStyle(DS.Color.textSecondary)
                            }

                            Spacer()

                            Button("Accept") {
                                Task { await store.acceptPartyInvite(invite) }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)

                            Button("Decline") {
                                Task { await store.declinePartyInvite(invite) }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        if invite.id != store.pendingPartyInvites.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NomNomPreview { _ in
        PendingPartyInvitesSection()
            .padding()
    }
}
