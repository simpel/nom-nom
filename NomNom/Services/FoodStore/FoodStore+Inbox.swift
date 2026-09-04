import Foundation
import Supabase
import UIKit
import UserNotifications

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

            struct SendMealInvitePayload: Encodable {
                let meal_id: String
                let invitee_email: String
            }
            let payload = SendMealInvitePayload(meal_id: mealID.uuidString, invitee_email: email)
            do {
                try await supabase.functions.invoke(
                    "send-invite-email",
                    options: FunctionInvokeOptions(body: payload)
                )
                Self.log.info("Meal invite email sent successfully to \(email)")
            } catch {
                Self.log.error("send-invite-email function returned error: \(error.localizedDescription)")
            }

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

    func askToRate(member: Profile, forMeal mealID: UUID) async -> Bool {
        guard member.id != userID else { return false }

        struct NewMemberInvite: Encodable {
            let meal_id: UUID
            let inviter_id: UUID
            let invitee_id: UUID
        }

        do {
            let created: MealInvite = try await supabase
                .from("meal_invites")
                .insert(NewMemberInvite(meal_id: mealID, inviter_id: userID, invitee_id: member.id))
                .select()
                .single()
                .execute()
                .value
            invites.append(created)
            reindex()

            if member.notifyEmailMealInvite {
                struct SendMemberMealInvitePayload: Encodable {
                    let meal_id: String
                    let invitee_user_id: String
                }
                let payload = SendMemberMealInvitePayload(
                    meal_id: mealID.uuidString,
                    invitee_user_id: member.id.uuidString
                )
                do {
                    try await supabase.functions.invoke(
                        "send-invite-email",
                        options: FunctionInvokeOptions(body: payload)
                    )
                    Self.log.info("Meal invite email sent to member \(member.shownName)")
                } catch {
                    Self.log.error("send-invite-email error for member: \(error.localizedDescription)")
                }
            }

            errorMessage = nil
            return true
        } catch let error as PostgrestError where error.code == "23505" {
            errorMessage = "\(member.shownName) has already been asked to rate this meal."
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
            updateAppBadge()
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func markUnread(_ notification: AppNotification) async {
        guard !notification.isUnread else { return }
        do {
            let updated: AppNotification = try await supabase
                .from("notifications")
                .update(NotificationUnreadPatch())
                .eq("id", value: notification.id.uuidString)
                .select()
                .single()
                .execute()
                .value
            if let index = notifications.firstIndex(where: { $0.id == updated.id }) {
                notifications[index] = updated
            }
            updateAppBadge()
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
            updateAppBadge()
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
            updateAppBadge()
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    private func updateAppBadge() {
        let count = unreadCount
        Task { @MainActor in
            if #available(iOS 16.0, *) {
                try? await UNUserNotificationCenter.current().setBadgeCount(count)
            } else {
                UIApplication.shared.applicationIconBadgeNumber = count
            }
        }
    }
}
