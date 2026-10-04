import Foundation

/// One AI-picked recipe for a dinner party, with the one-line reason the model gave.
struct PartyRecommendation: Codable, Hashable, Identifiable, Sendable {
    let dishID: UUID
    let reason: String

    var id: UUID { dishID }

    enum CodingKeys: String, CodingKey {
        case dishID = "dish_id"
        case reason
    }
}
