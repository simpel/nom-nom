import SwiftUI

/// Section displaying the dinner parties that the user follows.
/// If the user does not follow any parties, this section is completely hidden.
struct FollowedPartiesSection: View {
    @Environment(FoodStore.self) private var store

    private var followed: [Party] {
        store.followedParties
    }

    var body: some View {
        if !followed.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    "Parties You Follow",
                    trailingText: "\(followed.count)",
                    horizontalPadding: 0
                )

                VStack(spacing: DS.Spacing.md) {
                    ForEach(followed) { party in
                        PartyCard(party: party, showFollowButton: true)
                    }
                }
            }
        }
    }
}

#Preview {
    NomNomPreview { _ in
        FollowedPartiesSection()
            .padding()
    }
}
