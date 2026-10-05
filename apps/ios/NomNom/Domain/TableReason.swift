import Foundation

/// One reason a whole table scored a meal the way it did: a "what stood out" tag the
/// raters picked ("Too spicy", said by 2 of 3), or a pattern in their history (dishes
/// with coconut milk run 12 below their usual). Built on device by
/// `FoodStore.tableExplanation(forMeal:)`.
struct TableReason: Identifiable, Hashable {
    enum Source: Hashable {
        /// A rating tag picked on this meal.
        case tag(id: String)
        /// A history pattern (`RaterTagAffinity`) shared across the raters.
        case pattern(id: String)
    }

    let source: Source
    let title: String
    let detail: String
    /// Display points vs the raters' usual (0–100 scale); nil for tags, which carry a count.
    let delta: Int?
    /// How many raters picked the tag; nil for patterns.
    let count: Int?
    let isNegative: Bool

    var id: String {
        switch source {
        case .tag(let id): return "tag_\(id)"
        case .pattern(let id): return "pattern_\(id)"
        }
    }

    /// The figure on the row's badge: "−38", "+5", or "2 said".
    var figure: String {
        if let delta {
            return delta < 0 ? "\u{2212}\(abs(delta))" : "+\(delta)"
        }
        return "\(count ?? 1) said"
    }
}
