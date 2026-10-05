import Foundation

/// What a tag describes. Groups order the tag picker and let insights read a tag as a
/// flavour, texture or cooking signal. `why` holds the Can't-eat reasons.
enum RatingTagGroup: String, CaseIterable, Identifiable, Decodable, Sendable {
    case flavour, texture, cooking, feel, why

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flavour: return "Flavour"
        case .texture: return "Texture"
        case .cooking: return "Cooking"
        case .feel: return "Feel"
        case .why: return "Why"
        }
    }
}

/// One "what stood out" tag, from the `rating_tags` catalogue. A tag is offered for the
/// verdicts it names, on dishes whose kind or cooking method carries its trait
/// (`taxonomy_terms.rating_traits`). Good tags lift a score and problem tags lower it,
/// computed by `meal_rating_score` in the database; unscored tags only explain.
struct RatingTagOption: Identifiable, Hashable, Decodable, Sendable {
    let id: String
    let label: String
    let isPositive: Bool
    let scored: Bool
    let verdicts: [Int]
    let trait: String?
    let group: RatingTagGroup
    let sort: Int

    /// The trait every dish without `raw` has: cooking problems need a cooked dish.
    static let cookedTrait = "cooked"
    static let rawTrait = "raw"

    enum CodingKeys: String, CodingKey {
        case id, label, scored, verdicts, trait, sort
        case isPositive = "is_positive"
        case group = "tag_group"
    }

    func isOffered(for reaction: Reaction, traits: Set<String>) -> Bool {
        guard verdicts.contains(reaction.rawValue) else { return false }
        switch trait {
        case nil: return true
        case Self.cookedTrait: return !traits.contains(Self.rawTrait)
        case let trait?: return traits.contains(trait)
        }
    }
}
