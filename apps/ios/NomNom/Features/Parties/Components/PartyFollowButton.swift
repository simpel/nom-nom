import SwiftUI

/// Minimal, high-contrast button for following or unfollowing a public dinner party.
struct PartyFollowButton: View {
    let party: Party
    var size: ControlSize = .small

    @Environment(FoodStore.self) private var store
    @State private var isProcessing = false

    private var isMember: Bool {
        store.isMember(of: party.id)
    }

    private var isFollowing: Bool {
        store.isFollowing(partyID: party.id)
    }

    var body: some View {
        if !isMember && party.isPublic {
            AppButton(
                isFollowing ? "Following" : "Follow",
                variant: isFollowing ? .neutral : .primary,
                style: isFollowing ? .outlined : .normal,
                size: .sm,
                isPending: isProcessing,
                disabled: isProcessing
            ) {
                handleTap()
            }
            .accessibilityLabel(isFollowing ? "Unfollow \(party.name)" : "Follow \(party.name)")
        }
    }

    private func handleTap() {
        guard !isMember && party.isPublic else { return }
        guard !isProcessing else { return }
        isProcessing = true
        Task {
            if isFollowing {
                await store.unfollowParty(party)
            } else {
                await store.followParty(party)
            }
            isProcessing = false
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            HStack(spacing: 20) {
                PartyFollowButton(party: party)
            }
            .padding()
        }
    }
}
