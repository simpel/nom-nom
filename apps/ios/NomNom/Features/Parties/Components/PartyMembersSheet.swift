import SwiftUI

/// Dedicated modal sheet for managing members and pending invitations of a dinner party.
struct PartyMembersSheet: View {
    let party: Party

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showingInviteSheet = false
    @State private var memberToRemove: Profile?
    @State private var resentAlertMessage: String?
    @State private var actionError: String?

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
                    VStack(spacing: 12) {
                        ShareLink(
                            item: party.webInviteURL,
                            subject: Text("Join \(party.name) on Nom Nom"),
                            message: Text(party.shareMessage)
                        ) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Link")
                            }
                            .font(.callout.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(DS.Color.accentSoft)
                            .foregroundStyle(DS.Color.accentText)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        AppButton(
                            "Invite by Email",
                            systemImage: "envelope",
                            variant: .secondary,
                            style: .outlined,
                            size: .md,
                            isFullWidth: true
                        ) {
                            showingInviteSheet = true
                        }
                    }

                    if !pendingInvites.isEmpty {
                        invitesSection
                    }
                    
                    membersSection
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
            .alert(
                "Remove Member?",
                isPresented: Binding(
                    get: { memberToRemove != nil },
                    set: { if !$0 { memberToRemove = nil } }
                )
            ) {
                Button("Cancel", role: .cancel) {
                    memberToRemove = nil
                }
                if let member = memberToRemove {
                    Button("Remove \(member.shownName)", role: .destructive) {
                        Task {
                            await store.removeMember(user: member.id, from: party)
                            if let message = store.errorMessage {
                                actionError = message
                                store.errorMessage = nil
                            }
                        }
                    }
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
            .alert("Something Went Wrong", isPresented: Binding(
                get: { actionError != nil },
                set: { if !$0 { actionError = nil } }
            )) {
                Button("OK") { actionError = nil }
            } message: {
                Text(actionError ?? "")
            }
        }
    }

    // MARK: - Sections

    private var membersSection: some View {
        SectionCard("Current Members") {
            VStack(spacing: 0) {
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
                            AppButton(
                                systemImage: "minus.circle",
                                variant: .destructive,
                                style: .ghost,
                                size: .sm
                            ) {
                                memberToRemove = member
                            }
                            .accessibilityLabel("Remove \(member.shownName)")
                        }
                    }
                    .padding(.vertical, DS.Spacing.sm)

                    if index < members.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private var invitesSection: some View {
        SectionCard("Pending Invitations") {
            VStack(spacing: 0) {
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
                            AppButton("Resend", variant: .secondary, style: .outlined, size: .sm) {
                                Task {
                                    let ok = await store.resendPartyInvite(invite)
                                    if ok {
                                        resentAlertMessage = "Invitation resent to \(invite.inviteeEmail ?? "member")."
                                    } else {
                                        actionError = store.errorMessage
                                        store.errorMessage = nil
                                    }
                                }
                            }

                            AppButton(
                                systemImage: "trash",
                                variant: .destructive,
                                style: .ghost,
                                size: .sm
                            ) {
                                Task {
                                    await store.revokePartyInvite(invite)
                                    if let message = store.errorMessage {
                                        actionError = message
                                        store.errorMessage = nil
                                    }
                                }
                            }
                            .accessibilityLabel("Revoke invite")
                        }
                    }
                    .padding(.vertical, DS.Spacing.sm)

                    if index < pendingInvites.count - 1 {
                        Divider()
                    }
                }
            }
        }
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
