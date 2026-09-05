import SwiftUI

/// Dedicated modal sheet for managing members and pending invitations of a dinner party.
struct PartyMembersSheet: View {
    let party: Party

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showingInviteSheet = false
    @State private var memberToRemove: Profile?
    @State private var resentAlertMessage: String?

    private var members: [Profile] {
        store.members(of: party.id)
    }

    private var pendingInvites: [PartyInvite] {
        store.invites(forParty: party.id).filter { $0.isPending }
    }

    private var isCreatorOrHost: Bool {
        party.createdBy == store.userID
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.section) {
                    PartyInviteLinkCard(party: party)

                    membersSection

                    if !pendingInvites.isEmpty {
                        invitesSection
                    }

                    inviteButtonSection
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("Members", displayMode: .inline)
            .sheetOverviewToolbar(
                primarySystemImage: "person.badge.plus",
                onPrimaryAction: { showingInviteSheet = true }
            )
            .sheet(isPresented: $showingInviteSheet) {
                PartyInviteView(party: party)
            }
            .confirmationDialog(
                "Remove Member?",
                isPresented: Binding(
                    get: { memberToRemove != nil },
                    set: { if !$0 { memberToRemove = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let member = memberToRemove {
                    Button("Remove \(member.shownName)", role: .destructive) {
                        Task {
                            await store.removeMember(user: member.id, from: party)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    memberToRemove = nil
                }
            } message: {
                if let member = memberToRemove {
                    Text("\(member.shownName) will lose access to meals and ratings in this dinner party.")
                }
            }
            .alert("Invitation Resent", isPresented: Binding(
                get: { resentAlertMessage != nil },
                set: { if !$0 { resentAlertMessage = nil } }
            )) {
                Button("OK") { resentAlertMessage = nil }
            } message: {
                Text(resentAlertMessage ?? "")
            }
        }
    }

    // MARK: - Sections

    private var membersSection: some View {
        SectionCard("Current Members") {
            VStack(spacing: 8) {
                ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                    HStack(spacing: 12) {
                        UserAvatar(profile: member, size: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.shownName)
                                .font(.body.weight(.medium))
                                .foregroundStyle(DS.Color.textPrimary)

                            Text(memberRoleLabel(for: member))
                                .font(.caption2)
                                .foregroundStyle(DS.Color.textSecondary)
                        }

                        Spacer()

                        if canRemove(member: member) {
                            Button(role: .destructive) {
                                memberToRemove = member
                            } label: {
                                Image(systemName: "minus.circle")
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove \(member.shownName)")
                        }
                    }
                    .padding(.vertical, 3)

                    if index < members.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private var invitesSection: some View {
        SectionCard("Pending Invitations") {
            VStack(spacing: 8) {
                ForEach(Array(pendingInvites.enumerated()), id: \.element.id) { index, invite in
                    HStack(spacing: 12) {
                        Image(systemName: "envelope")
                            .font(.subheadline)
                            .foregroundStyle(DS.Color.textSecondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(invite.inviteeEmail ?? "Invited member")
                                .font(.subheadline)
                                .foregroundStyle(DS.Color.textPrimary)

                            Text("Pending")
                                .font(.caption2)
                                .foregroundStyle(DS.Color.accentText)
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Button("Resend") {
                                Task {
                                    let ok = await store.resendPartyInvite(invite)
                                    if ok {
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
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Revoke invite")
                        }
                    }
                    .padding(.vertical, 3)

                    if index < pendingInvites.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private var inviteButtonSection: some View {
        Button {
            showingInviteSheet = true
        } label: {
            HStack {
                Image(systemName: "person.badge.plus")
                    .fontWeight(.semibold)
                Text("Invite New Member")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(DS.Color.panel)
            .foregroundStyle(DS.Color.accentText)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func memberRoleLabel(for member: Profile) -> String {
        if member.id == party.createdBy {
            return member.id == store.userID ? "Host (You)" : "Host"
        } else if member.id == store.userID {
            return "Member (You)"
        } else {
            return "Member"
        }
    }

    private func canRemove(member: Profile) -> Bool {
        // Creator cannot be removed by anyone, and users cannot remove themselves through this button (they use Leave Party)
        guard member.id != party.createdBy, member.id != store.userID else { return false }
        return isCreatorOrHost || store.isMember(of: party.id)
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartyMembersSheet(party: party)
        }
    }
}
