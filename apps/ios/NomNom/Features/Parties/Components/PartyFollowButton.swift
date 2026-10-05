import SwiftUI

/// The follow control under a `discover` PartyCard or in a ListRow, for a public party the viewer isn't
/// a member of. It displays as an icon (`plus` for follow, `checkmark` for following) with 
/// `primary solid` or `primary soft` appearance, one request at a time, with a light haptic on change.
///
/// PartyCard README names this slot "Ask to join"; the app follows public parties
/// instead of requesting to join them (see DS-GAPS.md).
struct PartyFollowButton: View {
    let party: Party

    @Environment(FoodStore.self) private var store
    @State private var isProcessing = false

    private var isMember: Bool { store.isMember(of: party.id) }
    private var isFollowing: Bool { store.isFollowing(partyID: party.id) }

    var body: some View {
        if !isMember && party.isPublic {
            AppButton(
                icon: isFollowing ? "checkmark" : "plus",
                accessibilityLabel: isFollowing ? "Unfollow \(party.name)" : "Follow \(party.name)",
                appearance: isFollowing ? .soft : .solid,
                isLoading: isProcessing,
                action: toggleFollow
            )
            .sensoryFeedback(.impact(weight: .light), trigger: isFollowing)
        }
    }

    private func toggleFollow() {
        guard !isMember && party.isPublic, !isProcessing else { return }
        isProcessing = true
        Task {
            await store.toggleFollow(party: party)
            isProcessing = false
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartyFollowButton(party: party)
                .padding(DS.Spacing.gutter)
        }
    }
}
