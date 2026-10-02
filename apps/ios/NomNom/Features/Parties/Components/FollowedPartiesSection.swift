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
            DSSection("Parties you follow", trailing: "\(followed.count)") {
                VStack(spacing: DS.Spacing.s4) {
                    ForEach(followed) { DinnerPartyCard(party: $0) }
                }
            }
        }
    }
}

#Preview {
    NomNomPreview { _ in
        FollowedPartiesSection()
            .padding(DS.Spacing.gutter)
    }
}
