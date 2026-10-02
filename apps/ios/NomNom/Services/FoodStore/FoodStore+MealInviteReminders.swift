import Foundation
import Supabase

/// "Remind {name}" on the unrated rater sheet: one nudge a day per invite, through the
/// `remind_meal_invite` RPC, which files a fresh `rating_request` notification (and so
/// a push, unless the invitee has push off).
extension FoodStore {

    /// Where asking someone to rate a meal stands.
    enum RatingAskStatus: Equatable {
        /// Nobody has asked them yet.
        case notAsked
        /// Asked (or last reminded) at `since`; a reminder is allowed now.
        case canRemind(since: Date)
        /// Asked or reminded at `since`; the next reminder opens at `next`.
        case waiting(since: Date, next: Date, reminded: Bool)
    }

    /// The pending invite asking `profileID` to rate `mealID`, if any.
    func pendingInvite(for profileID: UUID, onMeal mealID: UUID) -> MealInvite? {
        invites(forMeal: mealID).first { $0.inviteeID == profileID && $0.status == .pending }
    }

    func ratingAskStatus(for profileID: UUID, onMeal mealID: UUID, now: Date = .now) -> RatingAskStatus {
        guard let invite = pendingInvite(for: profileID, onMeal: mealID) else { return .notAsked }
        if invite.canRemind(at: now) { return .canRemind(since: invite.lastNudgedAt) }
        return .waiting(since: invite.lastNudgedAt, next: invite.nextReminderAt, reminded: invite.remindedAt != nil)
    }

    /// Sends one reminder. Returns false (with `errorMessage` set) when it can't.
    func remindToRate(invite: MealInvite) async -> Bool {
        struct Params: Encodable { let p_invite_id: String }
        do {
            let updated: MealInvite = try await supabase
                .rpc("remind_meal_invite", params: Params(p_invite_id: invite.id.uuidString))
                .single()
                .execute()
                .value
            if let index = invites.firstIndex(where: { $0.id == updated.id }) {
                invites[index] = updated
            } else {
                invites.append(updated)
            }
            reindex()
            errorMessage = nil
            return true
        } catch let error as PostgrestError where error.code == "P0001" {
            errorMessage = "You can send one reminder a day."
            return false
        } catch {
            errorMessage = Self.describe(error)
            return false
        }
    }
}
