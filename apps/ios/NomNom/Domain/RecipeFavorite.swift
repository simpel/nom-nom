import Foundation

/// A record representing that a user has favorited a recipe.
struct RecipeFavorite: Identifiable, Hashable, Decodable {
    let id: UUID
    var recipeID: UUID
    var userID: UUID
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case recipeID = "recipe_id"
        case userID = "user_id"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        recipeID = try container.decode(UUID.self, forKey: .recipeID)
        userID = try container.decode(UUID.self, forKey: .userID)
        createdAt = try container.decodeTimestamp(.createdAt)
    }

    init(id: UUID = UUID(), recipeID: UUID, userID: UUID, createdAt: Date = .now) {
        self.id = id
        self.recipeID = recipeID
        self.userID = userID
        self.createdAt = createdAt
    }
}

typealias DishFavorite = RecipeFavorite

struct NewRecipeFavorite: Encodable {
    let recipe_id: UUID
    let user_id: UUID
}

typealias NewDishFavorite = NewRecipeFavorite
