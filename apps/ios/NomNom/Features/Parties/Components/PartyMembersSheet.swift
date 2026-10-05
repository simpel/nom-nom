import SwiftUI

/// Dedicated modal sheet for managing members and pending invitations of a dinner party.
struct PartyMembersSheet: View {
    let party: Party

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var memberToRemove: Profile?
    @State private var actionError: String?

    private var members: [Profile] {
        store.members(of: party.id)
    }

    private var pendingInvites: [PartyInvite] {
        store.pendingInvites(forParty: party.id)
    }

    private var isCreatorOrHost: Bool {
        party.createdBy == store.userID
    }

    var body: some View {
        NavigationStack {
            SheetBody {
                VStack(spacing: DS.Spacing.s3) {
                    ShareLink(
                        item: party.webInviteURL,
                        subject: Text("Join \(party.name) on Nom Nom"),
                        message: Text(party.shareMessage)
                    ) {
                        AppButtonLabel("Share link", icon: "square.and.arrow.up", appearance: .soft, fullWidth: true)
                    }
                    .buttonStyle(AppPressableButtonStyle())
                }

                membersSection
            }
            .screenTitle("Members", displayMode: .inline)
            .sheetOverviewToolbar()
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
            .alert("Something Went Wrong", isPresented: Binding(
                get: { actionError != nil },
                set: { if !$0 { actionError = nil } }
            )) {
                Button("OK") { actionError = nil }
            } message: {
                Text(actionError ?? "")
            }
        }
        .dsSheet()
    }

    // MARK: - Sections

    private var membersSection: some View {
        DSSection("Members", trailing: "\(members.count)") {
            Card(layout: .list) {
                ForEach(members) { member in
                    ListRow(
                        member.shownName,
                        meta: memberRoleLabel(for: member),
                        leading: .avatar(Avatar(profile: member, size: .sm, decorative: true)),
                        trailingAction: canRemove(member: member)
                            ? ListRowIconAction(icon: "xmark", accessibilityLabel: "Remove \(member.shownName)") {
                                memberToRemove = member
                            }
                            : nil
                    )
                }
                ForEach(pendingInvites) { PartyInviteRow(invite: $0) }
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
