import Foundation
import Supabase

extension FoodStore {

    func updateProfile(
        firstName: String,
        lastName: String,
        displayName: String? = nil,
        emoji: String = "🧑",
        newPhotoData: Data? = nil,
        removePhoto: Bool = false
    ) async {
        let cleanFirst = firstName.trimmedName
        let cleanLast = lastName.trimmedName
        let cleanDisplay = (displayName ?? "\(cleanFirst) \(cleanLast)").trimmedName

        do {
            var uploadedPath: String? = myProfile?.photoPath

            if let newPhotoData, let prepared = PhotoTools.prepare(newPhotoData) {
                let path = "\(userID.uuidString.lowercased())/avatar.jpg"
                PhotoCache.shared.put(prepared, for: path)
                _ = try? await supabase.storage
                    .from(SupabaseConfig.profileBucket)
                    .upload(path, data: prepared, options: FileOptions(contentType: "image/jpeg", upsert: true))
                uploadedPath = path
            } else if removePhoto {
                if let oldPath = myProfile?.photoPath {
                    _ = try? await supabase.storage
                        .from(SupabaseConfig.profileBucket)
                        .remove(paths: [oldPath])
                    PhotoCache.shared.forget(oldPath)
                }
                uploadedPath = nil
            }

            let updated: Profile = try await supabase
                .from("profiles")
                .update(ProfilePatch(
                    first_name: cleanFirst,
                    last_name: cleanLast,
                    display_name: cleanDisplay,
                    avatar_emoji: emoji,
                    photo_path: uploadedPath
                ))
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
