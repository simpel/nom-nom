import Foundation

/// Universal taxonomy term stored in Postgres `taxonomy_terms` table, representing
/// a standardized culinary entity (e.g. dish kinds, cooking methods, cuisines).
struct TaxonomyTermRecord: Identifiable, Hashable, Decodable, Sendable {
    let id: UUID
    let dimension: String
    let slug: String
    let name: String
    let aliases: [String]
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case dimension
        case slug
        case name
        case aliases
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        dimension = try container.decode(String.self, forKey: .dimension)
        slug = try container.decode(String.self, forKey: .slug)
        name = try container.decode(String.self, forKey: .name)
        aliases = try container.decodeIfPresent([String].self, forKey: .aliases) ?? []
        createdAt = try container.decodeTimestamp(.createdAt)
        updatedAt = try container.decodeTimestamp(.updatedAt)
    }

    init(
        id: UUID = UUID(),
        dimension: String,
        slug: String,
        name: String,
        aliases: [String] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.dimension = dimension
        self.slug = slug
        self.name = name
        self.aliases = aliases
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
