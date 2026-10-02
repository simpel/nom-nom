import SwiftUI

// PartyDetailView's DetailHeader, toolbar and actions.
extension PartyDetailView {
    /// Centred, avatar `xl`, name, meta, about and the action (members: Add meal, with
    /// inviting in the Members list; others: Follow, when public).
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
            return [DetailHeaderAction(title: "Add meal", icon: "plus") { showingCreateMeal = true }]
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
        ToolbarItem(placement: .topBarTrailing) {
            PageMenu {
                if store.isMember(of: party.id) {
                    Section {
                        Button("Edit party", systemImage: "pencil") { showingSettings = true }
                        Button("Edit members", systemImage: "person.2") { showingMembersSheet = true }
                        ShareLink(
                            item: party.webInviteURL,
                            subject: Text("Join \(party.name) on Nom Nom"),
                            message: Text(party.shareMessage)
                        ) {
                            Label("Share invite link", systemImage: "square.and.arrow.up")
                        }
                        Button("Leave party", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                            confirmLeave = true
                        }
                    }
                }
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
