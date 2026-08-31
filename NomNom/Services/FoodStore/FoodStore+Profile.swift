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
}
