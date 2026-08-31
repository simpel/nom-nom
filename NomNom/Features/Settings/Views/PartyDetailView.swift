import SwiftUI

/// Details of a single dinner party: member list, outgoing invites, party renaming, and leave action.
struct PartyDetailView: View {
    let partyID: UUID

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showingInvite = false
    @State private var showingRename = false
    @State private var newName = ""
    @State private var confirmLeave = false
    @State private var memberToRemove: Profile?

    private var party: Party? { store.party(partyID) }
    private var members: [Profile] { store.members(of: partyID) }
    private var invites: [PartyInvite] { store.invites(forParty: partyID) }

    var body: some View {
        Group {
            if let party {
                List {
                    headerSection(party: party)
                    membersSection(party: party)
                    if !invites.isEmpty {
                        invitesSection
                    }
                    dangerSection(party: party)
                }
                .navigationTitle(party.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingInvite = true
                        } label: {
                            Label("Invite", systemImage: "person.badge.plus")
                        }
                    }
                }
                .sheet(isPresented: $showingInvite) {
                    PartyInviteView(party: party)
                }
                .alert("Rename Party", isPresented: $showingRename) {
                    TextField("Party name", text: $newName)
                    Button("Save") {
                        Task { await store.updateParty(party, name: newName) }
                    }
                    Button("Cancel", role: .cancel) {}
                }
                .alert("Leave Party?", isPresented: $confirmLeave) {
                    Button("Leave", role: .destructive) {
                        Task {
                            await store.leaveParty(party)
                            dismiss()
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("You will lose access to meals served to this party. If you are the last member, the party will be deleted.")
                }
                .alert("Remove Member?", isPresented: Binding(
                    get: { memberToRemove != nil },
                    set: { if !$0 { memberToRemove = nil } }
                )) {
                    if let target = memberToRemove {
                        Button("Remove \(target.shownName)", role: .destructive) {
                            Task { await store.removeMember(user: target.id, from: party) }
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("They will no longer be able to see meals served to this party.")
                }
            } else {
                ContentUnavailableView("Party Not Found", systemImage: "person.2.slash")
            }
        }
    }

    private func headerSection(party: Party) -> some View {
        Section {
            HStack {
                Text(party.name)
                    .font(.headline)
                Spacer()
                Button("Rename") {
                    newName = party.name
                    showingRename = true
                }
                .font(.subheadline)
            }
        } header: {
            Text("Party Info")
        }
    }

    private func membersSection(party: Party) -> some View {
        Section("Members (\(members.count))") {
            ForEach(members) { member in
                HStack(spacing: 12) {
                    Text(member.avatarEmoji)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.shownName)
                            .font(.body)
                        if member.id == store.userID {
                            Text("You")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if member.id != store.userID {
                        Button(role: .destructive) {
                            memberToRemove = member
                        } label: {
                            Image(systemName: "minus.circle")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var invitesSection: some View {
        Section("Invited (\(invites.count))") {
            ForEach(invites) { invite in
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(invite.inviteeEmail ?? "Invited member")
                            .font(.subheadline)
                        Text(invite.status.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundStyle(invite.status == .pending ? .orange : .secondary)
                    }

                    Spacer()

                    if invite.isPending {
                        Button("Revoke", role: .destructive) {
                            Task { await store.revokePartyInvite(invite) }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func dangerSection(party: Party) -> some View {
        Section {
            Button(role: .destructive) {
                confirmLeave = true
            } label: {
                Label("Leave party", systemImage: "arrow.right.door")
            }
        }
    }
}
