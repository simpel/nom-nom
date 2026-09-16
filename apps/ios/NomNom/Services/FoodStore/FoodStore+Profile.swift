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

    /// Marks onboarding as done. Idempotent: once `onboarding_completed_at` is
    /// set, later calls (e.g. re-running onboarding to edit details) are no-ops.
    func completeOnboarding() async {
        guard myProfile?.onboardingCompletedAt == nil else { return }
        do {
            let updated: Profile = try await supabase
                .from("profiles")
                .update(OnboardingCompletionPatch())
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
        mealInvite: Bool,
        mealRating: Bool,
        partyInvite: Bool,
        partyActivity: Bool,
        recipeLike: Bool,
        viaPush: Bool,
        viaEmail: Bool
    ) async {
        let patch = ProfileNotificationPatch(
            notify_meal_invite: mealInvite,
            notify_meal_rating: mealRating,
            notify_party_invite: partyInvite,
            notify_party_activity: partyActivity,
            notify_recipe_like: recipeLike,
            notify_via_push: viaPush,
            notify_via_email: viaEmail
        )

        // Optimistic update
        if var current = myProfile {
            current.notifyMealInvite = mealInvite
            current.notifyMealRating = mealRating
            current.notifyPartyInvite = partyInvite
            current.notifyPartyActivity = partyActivity
            current.notifyRecipeLike = recipeLike
            current.notifyViaPush = viaPush
            current.notifyViaEmail = viaEmail
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
