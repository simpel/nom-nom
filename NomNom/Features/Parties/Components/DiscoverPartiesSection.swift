import SwiftUI

/// Section displaying public dinner parties available to follow.
/// Provides an instant 1-tap follow action and tap-to-open detail navigation.
struct DiscoverPartiesSection: View {
    @Environment(FoodStore.self) private var store

    private var discoverable: [Party] {
        store.discoverParties
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                "Parties to Follow",
                trailingText: discoverable.isEmpty ? nil : "\(discoverable.count)",
                horizontalPadding: 0
            )

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
                VStack(spacing: DS.Spacing.md) {
                    ForEach(discoverable) { party in
                        PartyCard(party: party, showFollowButton: true)
                    }
                }
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
