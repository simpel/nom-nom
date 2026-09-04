import Foundation

/// A dinner party: a lasting set of people who eat together.
struct Party: Identifiable, Hashable, Decodable {
    let id: UUID
    var name: String
    var about: String
    var isPublic: Bool
    var photoPath: String?
    let createdBy: UUID
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case about
        case isPublic = "is_public"
        case photoPath = "photo_path"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        about = try container.decodeIfPresent(String.self, forKey: .about) ?? ""
        isPublic = try container.decodeIfPresent(Bool.self, forKey: .isPublic) ?? false
        photoPath = try container.decodeIfPresent(String.self, forKey: .photoPath)
        createdBy = try container.decode(UUID.self, forKey: .createdBy)
        createdAt = try container.decodeTimestamp(.createdAt)
        updatedAt = try container.decodeTimestamp(.updatedAt)
    }

    init(
        id: UUID = UUID(),
        name: String,
        about: String = "",
        isPublic: Bool = false,
        photoPath: String? = nil,
        createdBy: UUID,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.about = about
        self.isPublic = isPublic
        self.photoPath = photoPath
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct PartyMember: Identifiable, Hashable, Decodable {
    let id: UUID
    let partyID: UUID
    let userID: UUID
    let joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case partyID = "party_id"
        case userID = "user_id"
        case joinedAt = "joined_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        partyID = try container.decode(UUID.self, forKey: .partyID)
        userID = try container.decode(UUID.self, forKey: .userID)
        joinedAt = try container.decodeTimestamp(.joinedAt)
    }

    init(id: UUID = UUID(), partyID: UUID, userID: UUID, joinedAt: Date = .now) {
        self.id = id
        self.partyID = partyID
        self.userID = userID
        self.joinedAt = joinedAt
    }
}

struct PartyInvite: Identifiable, Hashable, Decodable {
    let id: UUID
    let partyID: UUID
    let inviterID: UUID
    var inviteeID: UUID?
    var inviteeEmail: String?
    var status: InviteStatus
    let createdAt: Date
    var respondedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case partyID = "party_id"
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
        partyID = try container.decode(UUID.self, forKey: .partyID)
        inviterID = try container.decode(UUID.self, forKey: .inviterID)
        inviteeID = try container.decodeIfPresent(UUID.self, forKey: .inviteeID)
        inviteeEmail = try container.decodeIfPresent(String.self, forKey: .inviteeEmail)
        status = try container.decode(InviteStatus.self, forKey: .status)
        createdAt = try container.decodeTimestamp(.createdAt)
        respondedAt = try container.decodeTimestampIfPresent(.respondedAt)
    }

    var isPending: Bool { status == .pending }
}

struct MealParty: Identifiable, Hashable, Decodable {
    let id: UUID
    let mealID: UUID
    let partyID: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case mealID = "meal_id"
        case partyID = "party_id"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        mealID = try container.decode(UUID.self, forKey: .mealID)
        partyID = try container.decode(UUID.self, forKey: .partyID)
        createdAt = try container.decodeTimestamp(.createdAt)
    }

    init(id: UUID = UUID(), mealID: UUID, partyID: UUID, createdAt: Date = .now) {
        self.id = id
        self.mealID = mealID
        self.partyID = partyID
        self.createdAt = createdAt
    }
}

// MARK: - Party Followers

struct PartyFollower: Identifiable, Hashable, Decodable {
    let id: UUID
    let partyID: UUID
    let userID: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case partyID = "party_id"
        case userID = "user_id"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        partyID = try container.decode(UUID.self, forKey: .partyID)
        userID = try container.decode(UUID.self, forKey: .userID)
        createdAt = try container.decodeTimestamp(.createdAt)
    }

    init(id: UUID = UUID(), partyID: UUID, userID: UUID, createdAt: Date = .now) {
        self.id = id
        self.partyID = partyID
        self.userID = userID
        self.createdAt = createdAt
    }
}

// MARK: - Encodables for Database Operations

struct NewParty: Encodable {
    var id: UUID? = nil
    let name: String
    var about: String = ""
    var is_public: Bool = false
    var photo_path: String? = nil
    let created_by: UUID
}

struct PartyPatch: Encodable {
    var name: String?
    var about: String?
    var is_public: Bool?
    var photo_path: String?
}

typealias PartyNamePatch = PartyPatch

struct NewPartyMember: Encodable {
    let party_id: UUID
    let user_id: UUID
}

struct NewPartyFollower: Encodable {
    let party_id: UUID
    let user_id: UUID
}

struct NewPartyInvite: Encodable {
    let party_id: UUID
    let inviter_id: UUID
    let invitee_email: String
}

struct NewMealParty: Encodable {
    let meal_id: UUID
    let party_id: UUID
}

