import SwiftUI

/// Icon-only follow toggle for a public party the viewer isn't a member of (PartyCard):
/// an AppButton `sm`, `plus` while not following (`secondary soft`) and `checkmark`
/// while following (`primary soft`), with a light haptic on change. PartyDetailView
/// uses a labelled DetailHeader action with the same rules instead.
struct PartyFollowIconButton: View {
    let party: Party

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
                icon: isFollowing ? "checkmark" : "plus",
                accessibilityLabel: isFollowing ? "Unfollow \(party.name)" : "Follow \(party.name)",
                variant: isFollowing ? .primary : .secondary,
                appearance: .soft,
                isLoading: isProcessing
            ) {
                toggleFollow()
            }
            .disabled(isProcessing)
            .sensoryFeedback(.impact(weight: .light), trigger: isFollowing)
        }
    }

    private func toggleFollow() {
        guard !isMember && party.isPublic else { return }
        guard !isProcessing else { return }
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
            PartyFollowIconButton(party: party)
                .padding(DS.Spacing.gutter)
        }
    }
}
