import Foundation
import Supabase

extension FoodStore {

    func updateProfile(firstName: String, lastName: String, displayName: String? = nil, emoji: String) async {
        let cleanFirst = firstName.trimmedName
        let cleanLast = lastName.trimmedName
        let cleanDisplay = (displayName ?? "\(cleanFirst) \(cleanLast)").trimmedName

        do {
            let updated: Profile = try await supabase
                .from("profiles")
                .update(ProfilePatch(first_name: cleanFirst,
                                     last_name: cleanLast,
                                     display_name: cleanDisplay,
                                     avatar_emoji: emoji))
                .eq("id", value: userID.uuidString)
                .select()
                .single()
                .execute()
                .value
            profiles[updated.id] = updated
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func updateNotificationPreferences(
        pushParty: Bool,
        emailParty: Bool,
        pushMeal: Bool,
        emailMeal: Bool
    ) async {
        let patch = ProfileNotificationPatch(
            notify_push_party_invite: pushParty,
            notify_email_party_invite: emailParty,
            notify_push_meal_invite: pushMeal,
            notify_email_meal_invite: emailMeal
        )

        // Optimistic update
        if var current = myProfile {
            current.notifyPushPartyInvite = pushParty
            current.notifyEmailPartyInvite = emailParty
            current.notifyPushMealInvite = pushMeal
            current.notifyEmailMealInvite = emailMeal
            profiles[userID] = current
        }

        do {
            let updated: Profile = try await supabase
                .from("profiles")
                .update(patch)
                .eq("id", value: userID.uuidString)
                .select()
                .single()
                .execute()
                .value
            profiles[updated.id] = updated
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }
}
