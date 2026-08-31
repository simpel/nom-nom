import Foundation

/// A dish is the canonical *name* of something we cook. Every time we cook it we
/// add a `Meal` that points back here, which is what keeps the naming consistent.
///
/// `normalizedName` is the folded matching key, and the database's
/// `unique (owner_id, normalized_name)` is what actually stops "Tacos" and "tacos"
/// becoming two dishes — the client's find-or-create is the friendly path, not the
/// guarantee.
struct Dish: Identifiable, Hashable, Decodable {
    let id: UUID
    var ownerID: UUID
    /// The name as the user typed it (display form).
    var name: String
    /// Lowercased, diacritic-folded, whitespace-collapsed. Used for matching.
    var normalizedName: String
    /// Optional free-form tags, e.g. "quick", "oven", "veggie".
    var tags: [String]
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name
        case normalizedName = "normalized_name"
        case tags
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        ownerID = try container.decode(UUID.self, forKey: .ownerID)
        name = try container.decode(String.self, forKey: .name)
        normalizedName = try container.decode(String.self, forKey: .normalizedName)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        createdAt = try container.decodeTimestamp(.createdAt)
    }
}

// MARK: - Writes

/// Insert payload. Separate from `Dish` because the database fills in `id` and
/// `created_at`, and sending our own would either be ignored or fight the defaults.
struct NewDish: Encodable {
    let owner_id: UUID
    let name: String
    let normalized_name: String
    let tags: [String]

    init(ownerID: UUID, name: String, tags: [String] = []) {
        self.owner_id = ownerID
        self.name = name.trimmedName
        self.normalized_name = name.normalizedForMatching
        self.tags = tags
    }
}

/// Patch for a rename. Both columns move together or the match key drifts out of
/// step with the display name, which is the one thing this table exists to prevent.
struct DishNamePatch: Encodable {
    let name: String
    let normalized_name: String

    init(name: String) {
        self.name = name.trimmedName
        self.normalized_name = name.normalizedForMatching
    }
}

struct DishTagsPatch: Encodable {
    let tags: [String]
}
