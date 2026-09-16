import Foundation

/// Database model representing a cuisine or kitchen category stored in Postgres.
struct CategoryRecord: Identifiable, Hashable, Decodable, Sendable {
    let id: UUID
    var slug: String
    var name: String
    var photoPath: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case name
        case photoPath = "photo_path"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        slug = try container.decode(String.self, forKey: .slug)
        name = try container.decode(String.self, forKey: .name)
        photoPath = try container.decodeIfPresent(String.self, forKey: .photoPath)
        createdAt = try container.decodeTimestamp(.createdAt)
        updatedAt = try container.decodeTimestamp(.updatedAt)
    }

    init(
        id: UUID = UUID(),
        slug: String,
        name: String,
        photoPath: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.slug = slug
        self.name = name
        self.photoPath = photoPath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
