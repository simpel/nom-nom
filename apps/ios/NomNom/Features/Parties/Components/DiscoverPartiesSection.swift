import SwiftUI

/// Public dinner parties to follow: a DSSection over `discover` PartyCards with the
/// follow control under each card's link, or an EmptyState when there are none.
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
                VStack(spacing: DS.Spacing.s4) {
                    ForEach(discoverable) { DinnerPartyCard(party: $0) }
                }
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
