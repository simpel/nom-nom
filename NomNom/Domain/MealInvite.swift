import Foundation

enum InviteStatus: String, Decodable, Hashable {
    case pending
    case accepted
    case declined
}

/// Somebody asked to rate a meal.
///
/// `inviteeID` is null while the address has no account. Two triggers fill it in:
/// `link_invitee_by_email` on insert when the account already exists, and
/// `handle_new_user` later if that address signs up. Either way the notification is
/// filed the moment the link is made.
struct MealInvite: Identifiable, Hashable, Decodable {
    let id: UUID
    var mealID: UUID
    var inviterID: UUID
    var inviteeID: UUID?
    var inviteeEmail: String?
    var status: InviteStatus
    var createdAt: Date
    var respondedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case mealID = "meal_id"
        case inviterID = "inviter_id"
        case inviteeID = "invitee_id"
        case inviteeEmail = "invitee_email"
        case status
        case createdAt = "created_at"
        case respondedAt = "responded_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        mealID = try container.decode(UUID.self, forKey: .mealID)
        inviterID = try container.decode(UUID.self, forKey: .inviterID)
        inviteeID = try container.decodeIfPresent(UUID.self, forKey: .inviteeID)
        inviteeEmail = try container.decodeIfPresent(String.self, forKey: .inviteeEmail)
        status = try container.decodeIfPresent(InviteStatus.self, forKey: .status) ?? .pending
        createdAt = try container.decodeTimestamp(.createdAt)
        respondedAt = try container.decodeTimestampIfPresent(.respondedAt)
    }

    /// Nobody has an account for this address yet, so it is waiting on a signup.
    var isUnclaimed: Bool { inviteeID == nil }
}

struct NewInvite: Encodable {
    let meal_id: UUID
    let inviter_id: UUID
    let invitee_email: String
}

struct InviteStatusPatch: Encodable {
    let status: String
    let responded_at: String

    init(status: InviteStatus, at date: Date = .now) {
        self.status = status.rawValue
        // ISO8601 with a zone: the column is timestamptz, and sending a bare local
        // string would be read as whatever the server's zone happens to be.
        self.responded_at = ISO8601DateFormatter().string(from: date)
    }
}
