import SwiftUI

/// One row of `get_flavor_profile(scope, id)` — an aggregate taste signal for a single
/// canonical ingredient across a person's or party's rated meal history. Mirrors the web
/// admin dashboards (`apps/web/.../parties/[id]` and `.../users/[id]`), which render the
/// same RPC grouped by category.
struct FlavorProfileEntry: Identifiable, Hashable, Decodable {
    var id: UUID { canonicalIngredientID }
    let canonicalIngredientID: UUID
    let canonicalName: String
    let category: IngredientCategory
    let sampleSize: Int
    let lovedPct: Int
    let polarization: Int
    let sentiment: FlavorSentiment

    enum CodingKeys: String, CodingKey {
        case canonicalIngredientID = "canonical_ingredient_id"
        case canonicalName = "canonical_name"
        case category
        case sampleSize = "sample_size"
        case lovedPct = "loved_pct"
        case polarization
        case sentiment
    }
}

enum IngredientCategory: String, Decodable, CaseIterable {
    case spice, herb, protein, produce, dairy, grain, condiment, other

    var label: String {
        switch self {
        case .spice: "Spices"
        case .herb: "Herbs"
        case .protein: "Proteins"
        case .produce: "Produce"
        case .dairy: "Dairy"
        case .grain: "Grains"
        case .condiment: "Condiments"
        case .other: "Other"
        }
    }
}

enum FlavorSentiment: String, Decodable {
    case loved, mixed, polarizing, disliked, insufficient

    /// Reuses the existing reaction color scale rather than introducing new color assets —
    /// "loved" reads as a great reaction, "disliked" as a bad one, everything else as neutral.
    var tint: Color {
        switch self {
        case .loved: Reaction.great.text
        case .disliked: Reaction.bad.text
        case .mixed, .polarizing, .insufficient: Reaction.meh.text
        }
    }

    /// Polarizing shares "mixed"'s neutral color but needs its own signal (split opinions,
    /// not just an average one) — a small icon carries that instead of a new color asset.
    var systemImage: String? {
        self == .polarizing ? "arrow.left.and.right" : nil
    }
}

extension Array where Element == FlavorProfileEntry {
    /// Groups entries by category, ranked within each group by loved_pct, matching the
    /// web admin dashboards' presentation.
    func groupedByCategory() -> [(category: IngredientCategory, entries: [FlavorProfileEntry])] {
        Dictionary(grouping: self, by: \.category)
            .map { (category: $0.key, entries: $0.value.sorted { $0.lovedPct > $1.lovedPct }) }
            .sorted { $0.entries.count > $1.entries.count }
    }
}
