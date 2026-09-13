import Foundation

/// The public face of an account. Holds first name, last name, display name, avatar emoji,
/// and delivery preferences for notifications and email.
struct Profile: Identifiable, Hashable, Decodable {
    let id: UUID
    var firstName: String
    var lastName: String
    var displayName: String
    var avatarEmoji: String
    var photoPath: String?
    /// Per-event switches. Each turns one class of notification off entirely
    /// (push and email both). The in-app inbox is unaffected.
    var notifyMealInvite: Bool
    var notifyMealRating: Bool
    var notifyPartyInvite: Bool
    var notifyPartyActivity: Bool
    var notifyRecipeLike: Bool
    /// Global delivery channels, applied on top of the per-event switches.
    var notifyViaPush: Bool
    var notifyViaEmail: Bool
    var onboardingCompletedAt: Date?
    
    // MARK: - Subscription (Nom Nom Pro)
    var subscriptionStatus: String?
    var subscriptionExpiresAt: Date?
    var revenuecatAppUserId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case displayName = "display_name"
        case avatarEmoji = "avatar_emoji"
        case photoPath = "photo_path"
        case notifyMealInvite = "notify_meal_invite"
        case notifyMealRating = "notify_meal_rating"
        case notifyPartyInvite = "notify_party_invite"
        case notifyPartyActivity = "notify_party_activity"
        case notifyRecipeLike = "notify_recipe_like"
        case notifyViaPush = "notify_via_push"
        case notifyViaEmail = "notify_via_email"
        case onboardingCompletedAt = "onboarding_completed_at"
        case subscriptionStatus = "subscription_status"
        case subscriptionExpiresAt = "subscription_expires_at"
        case revenuecatAppUserId = "revenuecat_app_user_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? ""
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        avatarEmoji = try container.decodeIfPresent(String.self, forKey: .avatarEmoji) ?? "🧑"
        photoPath = try container.decodeIfPresent(String.self, forKey: .photoPath)
        notifyMealInvite = try container.decodeIfPresent(Bool.self, forKey: .notifyMealInvite) ?? true
        notifyMealRating = try container.decodeIfPresent(Bool.self, forKey: .notifyMealRating) ?? true
        notifyPartyInvite = try container.decodeIfPresent(Bool.self, forKey: .notifyPartyInvite) ?? true
        notifyPartyActivity = try container.decodeIfPresent(Bool.self, forKey: .notifyPartyActivity) ?? true
        notifyRecipeLike = try container.decodeIfPresent(Bool.self, forKey: .notifyRecipeLike) ?? true
        notifyViaPush = try container.decodeIfPresent(Bool.self, forKey: .notifyViaPush) ?? true
        notifyViaEmail = try container.decodeIfPresent(Bool.self, forKey: .notifyViaEmail) ?? false
        onboardingCompletedAt = try container.decodeTimestampIfPresent(.onboardingCompletedAt)
        subscriptionStatus = try container.decodeIfPresent(String.self, forKey: .subscriptionStatus)
        subscriptionExpiresAt = try container.decodeTimestampIfPresent(.subscriptionExpiresAt)
        revenuecatAppUserId = try container.decodeIfPresent(UUID.self, forKey: .revenuecatAppUserId)
    }

    init(
        id: UUID,
        firstName: String = "",
        lastName: String = "",
        displayName: String = "",
        avatarEmoji: String = "🧑",
        photoPath: String? = nil,
        notifyMealInvite: Bool = true,
        notifyMealRating: Bool = true,
        notifyPartyInvite: Bool = true,
        notifyPartyActivity: Bool = true,
        notifyRecipeLike: Bool = true,
        notifyViaPush: Bool = true,
        notifyViaEmail: Bool = false,
        onboardingCompletedAt: Date? = nil,
        subscriptionStatus: String? = nil,
        subscriptionExpiresAt: Date? = nil,
        revenuecatAppUserId: UUID? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.displayName = displayName
        self.avatarEmoji = avatarEmoji
        self.photoPath = photoPath
        self.notifyMealInvite = notifyMealInvite
        self.notifyMealRating = notifyMealRating
        self.notifyPartyInvite = notifyPartyInvite
        self.notifyPartyActivity = notifyPartyActivity
        self.notifyRecipeLike = notifyRecipeLike
        self.notifyViaPush = notifyViaPush
        self.notifyViaEmail = notifyViaEmail
        self.onboardingCompletedAt = onboardingCompletedAt
        self.subscriptionStatus = subscriptionStatus
        self.subscriptionExpiresAt = subscriptionExpiresAt
        self.revenuecatAppUserId = revenuecatAppUserId
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
    let photo_path: String?
}

struct ProfileNotificationPatch: Encodable {
    let notify_meal_invite: Bool
    let notify_meal_rating: Bool
    let notify_party_invite: Bool
    let notify_party_activity: Bool
    let notify_recipe_like: Bool
    let notify_via_push: Bool
    let notify_via_email: Bool
}

struct OnboardingCompletionPatch: Encodable {
    let onboarding_completed_at: String

    init(at date: Date = .now) {
        // ISO8601 with a zone: the column is timestamptz, and sending a bare local
        // string would be read as whatever the server's zone happens to be.
        self.onboarding_completed_at = ISO8601DateFormatter().string(from: date)
    }
}
