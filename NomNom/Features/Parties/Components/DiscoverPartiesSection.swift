import SwiftUI

/// Section displaying public dinner parties available to follow.
/// Provides an instant 1-tap follow action and tap-to-open detail navigation.
struct DiscoverPartiesSection: View {
    @Environment(FoodStore.self) private var store

    private var discoverable: [Party] {
        store.discoverParties
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageHeading(title: "Parties to follow")

            if discoverable.isEmpty {
                SectionCard {
                    VStack(spacing: 4) {
                        Text("No new parties to follow right now")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(DS.Color.textPrimary)

                        Text("New public dinner parties created by other food lovers will appear here.")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.md) {
                        ForEach(discoverable) { party in
                            PartyCard(party: party, showFollowButton: true)
                                .frame(width: 320)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.screenHorizontal)
                }
                .padding(.horizontal, -DS.Spacing.screenHorizontal)
            }
        }
    }
}

#Preview {
    NomNomPreview { _ in
        DiscoverPartiesSection()
            .padding()
    }
}
