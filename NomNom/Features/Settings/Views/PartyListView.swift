import SwiftUI

/// List of Dinner Parties the user is part of, plus incoming invitations and a creation flow.
struct PartyListView: View {
    @Environment(FoodStore.self) private var store

    @Environment(\.dismiss) private var dismiss

    @State private var showingCreate = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !store.pendingPartyInvites.isEmpty {
                    pendingInvitesSection
                }

                partiesSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(DS.Color.bg)
        .screenTitle("Dinner Parties")
        .sheetDoneToolbar(primarySystemImage: "plus", onPrimaryAction: {
            showingCreate = true
        })
        .sheet(isPresented: $showingCreate) {
            CreatePartySheet()
        }
    }

    private var pendingInvitesSection: some View {
        SectionCard("Pending Invitations") {
            VStack(spacing: 12) {
                ForEach(store.pendingPartyInvites) { invite in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            let party = store.party(invite.partyID)
                            Text(party?.name ?? "Dinner Party")
                                .font(.body.weight(.medium))
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

    private var partiesSection: some View {
        SectionCard("Your Parties") {
            VStack(alignment: .leading, spacing: 12) {
                if store.myParties.isEmpty {
                    Text("No Dinner Parties yet. Create one to share meals and ratings.")
                        .font(.subheadline)
                        .foregroundStyle(DS.Color.textTertiary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(store.myParties) { party in
                        NavigationLink {
                            PartyDetailView(partyID: party.id)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.2.fill")
                                    .font(.title3)
                                    .foregroundStyle(.tint)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(party.name)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(DS.Color.textPrimary)
                                    let memberCount = store.members(of: party.id).count
                                    Text("\(memberCount) \(memberCount == 1 ? "member" : "members")")
                                        .font(.caption)
                                        .monospacedDigit()
                                        .foregroundStyle(DS.Color.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(DS.Color.textTertiary)
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)

                        if party.id != store.myParties.last?.id {
                            Divider()
                        }
                    }
                }

            
            }
        }
    }
}
