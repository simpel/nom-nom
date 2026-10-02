import SwiftUI

// PartyDetailView's DetailHeader, toolbar and actions.
extension PartyDetailView {
    /// The README's Dinner party recipe: centred, avatar `xl`, name, meta, about and
    /// the actions (members: Log a meal + Invite; others: Follow, when public).
    func header(for party: Party) -> some View {
        DetailHeader(
            title: party.name,
            align: .center,
            meta: meta(for: party),
            summary: party.about,
            avatar: Avatar(party: party),
            actions: actions(for: party)
        )
    }

    private func meta(for party: Party) -> String {
        let memberCount = store.members(of: party.id).count
        let followerCount = store.followers(of: party.id).count
        var parts = ["\(memberCount) \(memberCount == 1 ? "member" : "members")"]
        if followerCount > 0 {
            parts.append("\(followerCount) \(followerCount == 1 ? "follower" : "followers")")
        }
        if !party.isPublic {
            parts.append("Private")
        }
        return parts.joined(separator: " \u{00B7} ")
    }

    private func actions(for party: Party) -> [DetailHeaderAction] {
        if store.isMember(of: party.id) {
            return [
                DetailHeaderAction(title: "Log a meal") { showingCreateMeal = true },
                // README Dinner party recipe: "Log a meal" + `secondary soft` "Invite".
                DetailHeaderAction(title: "Invite", variant: .secondary, appearance: .soft) { showingInvite = true },
            ]
        }
        guard party.isPublic else { return [] }
        let isFollowing = store.isFollowing(partyID: party.id)
        return [
            DetailHeaderAction(
                title: isFollowing ? "Following" : "Follow",
                icon: isFollowing ? "checkmark" : nil,
                appearance: isFollowing ? .soft : .solid,
                isLoading: isFollowProcessing
            ) { toggleFollow(party) },
        ]
    }

    /// Same rules as PartyFollowButton: only non-members of public parties, one
    /// request at a time. Errors surface in the screen's alert.
    private func toggleFollow(_ party: Party) {
        guard !store.isMember(of: party.id), party.isPublic, !isFollowProcessing else { return }
        isFollowProcessing = true
        Task {
            await store.toggleFollow(party: party)
            isFollowProcessing = false
            if let message = store.errorMessage {
                actionError = message
                store.errorMessage = nil
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }

    func leave(_ party: Party) {
        Task {
            await store.leaveParty(party)
            if store.errorMessage == nil {
                dismiss()
            } else {
                actionError = store.errorMessage
                store.errorMessage = nil
            }
        }
    }

    @ToolbarContentBuilder
    func toolbarContent(for party: Party) -> some ToolbarContent {
        if store.isMember(of: party.id) {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingSettings = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button { showingMembersSheet = true } label: {
                        Label("Edit members", systemImage: "person.2")
                    }
                    ShareLink(
                        item: party.webInviteURL,
                        subject: Text("Join \(party.name) on Nom Nom"),
                        message: Text(party.shareMessage)
                    ) {
                        Label("Share invite link", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) { confirmLeave = true } label: {
                        Label("Leave party", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis").fontWeight(.semibold)
                }
                .accessibilityLabel("Party options")
            }
        }
    }
}

/// The leading sheet close (`sheetCloseToolbar`) when the screen is presented modally.
struct PartyDetailCloseToolbar: ViewModifier {
    let isShown: Bool

    func body(content: Content) -> some View {
        if isShown {
            content.sheetCloseToolbar()
        } else {
            content
        }
    }
}
