import SwiftUI

/// Public dinner parties to follow: a DSSection over a horizontal row of PartyCards
/// with a 1-tap follow action, or an EmptyState when there are none.
struct DiscoverPartiesSection: View {
    @Environment(FoodStore.self) private var store

    private var discoverable: [Party] {
        store.discoverParties
    }

    var body: some View {
        DSSection("Parties to follow") {
            if discoverable.isEmpty {
                EmptyState(
                    "No new parties to follow",
                    message: "Public dinner parties other people start will show up here."
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.s4) {
                        ForEach(discoverable) { party in
                            // No README width for a scrolled PartyCard: `spacing-72`
                            // (see DS-GAPS "PartyCard in a scroller").
                            PartyCard(party: party, showFollowButton: true)
                                .frame(width: DS.Spacing.s72)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.gutter)
                }
                .padding(.horizontal, -DS.Spacing.gutter)
            }
        }
    }
}

#Preview {
    NomNomPreview { _ in
        DiscoverPartiesSection()
            .padding(DS.Spacing.gutter)
    }
}
