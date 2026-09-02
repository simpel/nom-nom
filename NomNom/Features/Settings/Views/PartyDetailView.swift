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
    @State private var resentAlertMessage: String?

    private var party: Party? { store.party(partyID) }
    private var members: [Profile] { store.members(of: partyID) }
    private var invites: [PartyInvite] { store.invites(forParty: partyID) }

    var body: some View {
        Group {
            if let party {
                ScrollView {
                    VStack(spacing: 16) {
                        headerSection(party: party)
                        membersSection(party: party)
                        if !invites.isEmpty {
                            invitesSection
                        }
                        dangerSection(party: party)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .background(Color(uiColor: .systemGroupedBackground))
                .screenTitle(party.name)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
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
                .alert("Invitation Resent", isPresented: Binding(
                    get: { resentAlertMessage != nil },
                    set: { if !$0 { resentAlertMessage = nil } }
                )) {
                    Button("OK") { resentAlertMessage = nil }
                } message: {
                    Text(resentAlertMessage ?? "")
                }
            } else {
                ContentUnavailableView("Party Not Found", systemImage: "person.2.slash")
            }
        }
    }

    private func headerSection(party: Party) -> some View {
        SectionCard("Party Info") {
            HStack {
                Text(party.name)
                    .font(.body.weight(.medium))
                Spacer()
                Button("Rename") {
                    newName = party.name
                    showingRename = true
                }
                .font(.subheadline)
            }
        }
    }

    private func membersSection(party: Party) -> some View {
        SectionCard("Members (\(members.count))") {
            VStack(spacing: 8) {
                ForEach(members) { member in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.12))
                                .frame(width: 32, height: 32)
                            Text(member.shownName.prefix(1).uppercased())
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.accentColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.shownName)
                                .font(.body)
                                .foregroundStyle(.primary)
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

                    Divider()
                }

                Button {
                    showingInvite = true
                } label: {
                    Label("Invite member", systemImage: "person.badge.plus")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }

    private var invitesSection: some View {
        SectionCard("Invited (\(invites.count))") {
            VStack(spacing: 8) {
                ForEach(invites) { invite in
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(invite.inviteeEmail ?? "Invited member")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Text(invite.status.rawValue.capitalized)
                                .font(.caption2)
                                .foregroundStyle(invite.status == .pending ? .orange : .secondary)
                        }

                        Spacer()

                        if invite.isPending {
                            HStack(spacing: 8) {
                                Button("Resend") {
                                    Task {
                                        let success = await store.resendPartyInvite(invite)
                                        if success {
                                            resentAlertMessage = "Invitation resent to \(invite.inviteeEmail ?? "member")."
                                        }
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                Button(role: .destructive) {
                                    Task { await store.revokePartyInvite(invite) }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 2)

                    if invite.id != invites.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private func dangerSection(party: Party) -> some View {
        SectionCard {
            Button(role: .destructive) {
                confirmLeave = true
            } label: {
                Label("Leave party", systemImage: "arrow.right.door")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
}
