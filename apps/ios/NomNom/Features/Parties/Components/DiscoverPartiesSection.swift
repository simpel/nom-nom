import SwiftUI

/// Section displaying public dinner parties available to follow: `discover` PartyCards
/// with the follow control under each card's link.
struct DiscoverPartiesSection: View {
    @Environment(FoodStore.self) private var store

    private var discoverable: [Party] {
        store.discoverParties
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            PageHeading(title: "Parties to follow")

            if discoverable.isEmpty {
                SectionCard {
                    VStack(spacing: DS.Spacing.s1) {
                        Text("No new parties to follow right now")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(DS.Color.textPrimary)

                        Text("New public dinner parties created by other food lovers will appear here.")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DS.Spacing.s2)
                }
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
