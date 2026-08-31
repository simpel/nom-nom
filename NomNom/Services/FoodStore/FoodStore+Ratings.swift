import Foundation
import Supabase

extension FoodStore {

    func rate(mealID: UUID, as reaction: Reaction) async {
        do {
            if let existing = ratings(forMeal: mealID).first(where: { $0.raterID == userID }) {
                let updated: MealRating = try await supabase
                    .from("meal_ratings")
                    .update(RatingPatch(reaction: reaction.rawValue))
                    .eq("id", value: existing.id.uuidString)
                    .select()
                    .single()
                    .execute()
                    .value
                upsertLocal(rating: updated)
            } else {
                let created: MealRating = try await supabase
                    .from("meal_ratings")
                    .insert(NewRating(mealID: mealID, source: .account(userID), reaction: reaction))
                    .select()
                    .single()
                    .execute()
                    .value
                upsertLocal(rating: created)
            }

            if let invite = invites.first(where: { $0.mealID == mealID && $0.inviteeID == userID }),
               invite.status != .accepted {
                try await setInviteStatus(invite, to: .accepted)
            }
            reindex()
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func myRating(forMeal mealID: UUID) -> Reaction? {
        ratings(forMeal: mealID).first { $0.raterID == userID }?.reaction
    }
}
