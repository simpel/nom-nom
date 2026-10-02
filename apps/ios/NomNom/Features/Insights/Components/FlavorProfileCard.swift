import SwiftUI

/// Ingredient taste profile grouped by category, sourced from the server-aggregated
/// `get_flavor_profile` RPC — scope-agnostic, used for both a party's shared profile and
/// one person's own. One DSSection per category over ListRow key–value rows: the
/// ingredient, its sentiment as meta, and the share of ratings that loved it as the
/// tabular value. (The old chips put a word and a number in one pill, which Badge
/// forbids: "never a number and a word together".)
struct FlavorProfileCard: View {
    let entries: [FlavorProfileEntry]

    var body: some View {
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: DS.Spacing.block) {
                ForEach(entries.groupedByCategory(), id: \.category) { group in
                    DSSection(group.category.label) {
                        Card(layout: .list) {
                            ForEach(group.entries) { entry in
                                ListRow(entry.canonicalName, meta: entry.sentiment.label, value: "\(entry.lovedPct)% loved")
                            }
                        }
                    }
                }
            }
        }
    }
}

private extension FlavorSentiment {
    var label: String? {
        switch self {
        case .loved, .insufficient: return nil
        case .mixed: return "Mixed"
        case .polarizing: return "Splits the table"
        case .disliked: return "Disliked"
        }
    }
}
