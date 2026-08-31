import Foundation

/// Somebody whose opinion we track but who has no account — typically one of the
/// kids. Without this the move to Postgres would have quietly dropped the app's
/// original feature, since only invited adults get an `auth.users` row.
struct Eater: Identifiable, Hashable, Decodable {
    let id: UUID
    var ownerID: UUID
    var name: String
    /// Emoji used as a tiny avatar in the UI.
    var emoji: String
    var isActive: Bool
    var sortIndex: Int
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name
        case emoji
        case isActive = "is_active"
        case sortIndex = "sort_index"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        ownerID = try container.decode(UUID.self, forKey: .ownerID)
        name = try container.decode(String.self, forKey: .name)
        emoji = try container.decodeIfPresent(String.self, forKey: .emoji) ?? "🧒"
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        sortIndex = try container.decodeIfPresent(Int.self, forKey: .sortIndex) ?? 0
        createdAt = try container.decodeTimestamp(.createdAt)
    }

    var raterRef: RaterRef { .eater(id) }
}

struct NewEater: Encodable {
    let owner_id: UUID
    let name: String
    let emoji: String
    let sort_index: Int
}

struct EaterPatch: Encodable {
    let name: String
    let emoji: String
    let is_active: Bool
    let sort_index: Int
}
