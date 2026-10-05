import SwiftUI

// PartyDetailView's ScreenHeader, toolbar and actions.
extension PartyDetailView {
    /// Centred by its avatar: name, about and the action (members: Add meal, with
    /// inviting in the Members list; others: Follow, when public). Any member can
    /// change the party photo from the avatar's pen.
    func header(for party: Party) -> some View {
        ScreenHeader(
            party.name,
            summary: party.about,
            avatar: Avatar(party: party),
            avatarEdit: store.isMember(of: party.id) ? ScreenHeaderAvatarEdit(
                hasPhoto: !party.photoPaths.isEmpty,
                onPick: { setCover($0, for: party) },
                onRemove: { setCover(nil, for: party) }
            ) : nil,
            actions: actions(for: party)
        )
    }

    private func setCover(_ data: Data?, for party: Party) {
        Task {
            await store.setPartyCover(data, for: party)
            if let message = store.errorMessage {
                actionError = message
                store.errorMessage = nil
            }
        }
    }

    private func actions(for party: Party) -> [ScreenHeaderAction] {
        if store.isMember(of: party.id) {
            return [ScreenHeaderAction(title: "Add meal") { showingCreateMeal = true }]
        }
        guard party.isPublic else { return [] }
        let isFollowing = store.isFollowing(partyID: party.id)
        return [
            ScreenHeaderAction(
                title: isFollowing ? "Following" : "Follow",
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
