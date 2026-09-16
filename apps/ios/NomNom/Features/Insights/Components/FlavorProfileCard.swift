import SwiftUI

/// Ingredient taste profile grouped by category, sourced from the server-aggregated
/// `get_flavor_profile` RPC — scope-agnostic, used for both a party's shared profile and
/// one person's own.
struct FlavorProfileCard: View {
    let entries: [FlavorProfileEntry]

    var body: some View {
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text("Ingredient Profile")
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)

                ForEach(entries.groupedByCategory(), id: \.category) { group in
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text(group.category.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DS.Color.textSecondary)

                        WrappingHStack {
                            ForEach(group.entries) { entry in
                                Chip(
                                    text: "\(entry.canonicalName) \(entry.lovedPct)%",
                                    systemImage: entry.sentiment.systemImage,
                                    tint: entry.sentiment.tint
                                )
                            }
                        }
                    }
                }
            }
            .padding(DS.Spacing.md)
            .background(DS.Color.sunken)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
    }
}
