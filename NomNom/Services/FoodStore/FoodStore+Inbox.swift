import Foundation
import Supabase

extension FoodStore {

    func invite(email rawEmail: String, toMeal mealID: UUID) async -> Bool {
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard email.contains("@") else {
            errorMessage = "That doesn't look like an email address."
            return false
        }
        if let myEmail = supabase.auth.currentUser?.email?.lowercased(), email == myEmail {
            errorMessage = "You cannot invite yourself."
            return false
        }
        do {
            let created: MealInvite = try await supabase
                .from("meal_invites")
                .insert(NewInvite(meal_id: mealID, inviter_id: userID, invitee_email: email))
                .select()
                .single()
                .execute()
                .value
            invites.append(created)
            reindex()
            try? await loadProfiles()
            errorMessage = nil
            return true
        } catch let error as PostgrestError where error.code == "23505" {
            errorMessage = "\(email) has already been invited to this meal."
            return false
        } catch {
            errorMessage = Self.describe(error)
            return false
        }
    }

    func decline(invite: MealInvite) async {
        do {
            try await setInviteStatus(invite, to: .declined)
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func setInviteStatus(_ invite: MealInvite, to status: InviteStatus) async throws {
        let updated: MealInvite = try await supabase
            .from("meal_invites")
            .update(InviteStatusPatch(status: status))
            .eq("id", value: invite.id.uuidString)
            .select()
            .single()
            .execute()
            .value
        if let index = invites.firstIndex(where: { $0.id == updated.id }) {
            invites[index] = updated
        }
        reindex()
    }

    func revoke(invite: MealInvite) async {
        do {
            try await supabase.from("meal_invites").delete().eq("id", value: invite.id.uuidString).execute()
            invites.removeAll { $0.id == invite.id }
            reindex()
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func markRead(_ notification: AppNotification) async {
        guard notification.isUnread else { return }
        do {
            let updated: AppNotification = try await supabase
                .from("notifications")
                .update(NotificationReadPatch())
                .eq("id", value: notification.id.uuidString)
                .select()
                .single()
                .execute()
                .value
            if let index = notifications.firstIndex(where: { $0.id == updated.id }) {
                notifications[index] = updated
            }
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func markAllRead() async {
        guard unreadCount > 0 else { return }
        do {
            try await supabase
                .from("notifications")
                .update(NotificationReadPatch())
                .eq("user_id", value: userID.uuidString)
                .is("read_at", value: nil)
                .execute()
            let now = Date.now
            for index in notifications.indices where notifications[index].readAt == nil {
                notifications[index].readAt = now
            }
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func delete(notification: AppNotification) async {
        do {
            try await supabase
                .from("notifications")
                .delete()
                .eq("id", value: notification.id.uuidString)
                .execute()
            notifications.removeAll { $0.id == notification.id }
        } catch {
            errorMessage = Self.describe(error)
        }
    }
}
