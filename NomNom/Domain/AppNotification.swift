import Foundation

/// An entry in the in-app inbox.
struct AppNotification: Identifiable, Hashable, Decodable {
    enum Kind: String, Decodable, Hashable {
        /// Somebody invited you to rate their meal.
        case ratingRequest = "rating_request"
        /// Somebody rated a meal you cooked.
        case ratingReceived = "rating_received"
        /// Somebody invited you to join a dinner party.
        case partyInvite = "party_invite"
        /// Somebody joined a dinner party.
        case partyJoined = "party_joined"
        /// Unknown or future notification kind.
        case other = "other"
    }

    let id: UUID
    var userID: UUID
    var mealID: UUID?
    var kind: Kind
    var title: String
    var body: String
    var readAt: Date?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case mealID = "meal_id"
        case kind
        case title
        case body
        case readAt = "read_at"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userID = try container.decode(UUID.self, forKey: .userID)
        mealID = try container.decodeIfPresent(UUID.self, forKey: .mealID)
        let rawKind = try container.decode(String.self, forKey: .kind)
        kind = Kind(rawValue: rawKind) ?? .other
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        readAt = try container.decodeTimestampIfPresent(.readAt)
        createdAt = try container.decodeTimestamp(.createdAt)
    }

    var isUnread: Bool { readAt == nil }

    var symbol: String {
        switch kind {
        case .ratingRequest: return "hand.raised.fill"
        case .ratingReceived: return "star.bubble.fill"
        case .partyInvite: return "person.2.fill"
        case .partyJoined: return "person.crop.circle.badge.plus"
        case .other: return "bell.fill"
        }
    }
}

struct NotificationReadPatch: Encodable {
    let read_at: String

    init(at date: Date = .now) {
        self.read_at = ISO8601DateFormatter().string(from: date)
    }
}
