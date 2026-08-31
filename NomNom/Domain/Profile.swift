import Foundation

/// The public face of an account. Holds first name, last name, display name, and an avatar emoji.
/// Notably there is no email here, so one user cannot read another's address off the table.
struct Profile: Identifiable, Hashable, Decodable {
    let id: UUID
    var firstName: String
    var lastName: String
    var displayName: String
    var avatarEmoji: String

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case displayName = "display_name"
        case avatarEmoji = "avatar_emoji"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? ""
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        avatarEmoji = try container.decodeIfPresent(String.self, forKey: .avatarEmoji) ?? "🧑"
    }

    init(id: UUID, firstName: String = "", lastName: String = "", displayName: String = "", avatarEmoji: String = "🧑") {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.displayName = displayName
        self.avatarEmoji = avatarEmoji
    }

    /// Prefer the first and last name if available, otherwise fall back to display name or "Someone".
    var shownName: String {
        let full = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        if !full.isEmpty { return full }
        return displayName.isEmpty ? "Someone" : displayName
    }

    var shortName: String {
        let first = firstName.trimmingCharacters(in: .whitespaces)
        if !first.isEmpty { return first }
        let last = lastName.trimmingCharacters(in: .whitespaces)
        if !last.isEmpty { return last }
        return displayName.isEmpty ? "Someone" : displayName
    }

    var raterRef: RaterRef { .account(id) }
}

struct ProfilePatch: Encodable {
    let first_name: String
    let last_name: String
    let display_name: String
    let avatar_emoji: String
}
