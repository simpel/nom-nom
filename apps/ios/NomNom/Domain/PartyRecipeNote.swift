import Foundation

/// What one dinner party has learned about a recipe ("Halve the chilli"), from
/// `party_recipe_notes`. One per party per recipe, so a recipe can carry several notes,
/// one per table. Nom Nom Pro.
struct PartyRecipeNote: Identifiable, Hashable, Decodable {
    let id: UUID
    var partyID: UUID
    var dishID: UUID
    var body: String
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, body
        case partyID = "party_id"
        case dishID = "dish_id"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        partyID = try container.decode(UUID.self, forKey: .partyID)
        dishID = try container.decode(UUID.self, forKey: .dishID)
        body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        updatedAt = try container.decodeTimestamp(.updatedAt)
    }

    init(id: UUID = UUID(), partyID: UUID, dishID: UUID, body: String, updatedAt: Date = .now) {
        self.id = id
        self.partyID = partyID
        self.dishID = dishID
        self.body = body
        self.updatedAt = updatedAt
    }
}
