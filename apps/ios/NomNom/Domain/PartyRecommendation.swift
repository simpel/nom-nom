import Foundation

/// One AI-picked recipe for a dinner party, with the one-line reason the model gave.
struct PartyRecommendation: Codable, Hashable, Identifiable, Sendable {
    let recipeID: UUID
    let reason: String

    var id: UUID { recipeID }

    enum CodingKeys: String, CodingKey {
        case recipeID = "recipe_id"
        case reason
    }
}
