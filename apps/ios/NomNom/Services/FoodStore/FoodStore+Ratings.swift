import Foundation
import Supabase

extension FoodStore {

    /// Whether the viewer was at the table and may rate this meal: the cook, anyone
    /// asked to rate it, or a member of a party it was served to. Mirrors
    /// `can_rate_meal` (RLS). Following a public party lets you read a meal, not rate it.
    func canRate(meal: Meal) -> Bool {
        meal.createdBy == userID
            || invites(forMeal: meal.id).contains { $0.inviteeID == userID }
            || parties(forMeal: meal.id).contains { isMember(of: $0.id) }
    }

    /// Saves the viewer's own rating with everything they said about the meal. Only
    /// ever writes the viewer's row: nobody rates for anybody else.
    @discardableResult
    func saveMyRating(mealID: UUID, answers: RatingAnswers) async -> Bool {
        guard let reaction = answers.reaction else { return false }
        do {
            if let existing = rating(for: .account(userID), on: mealID) {
                let updated: MealRating = try await supabase
                    .from("meal_ratings")
                    .update(RatingPatch(reaction: reaction, answers: answers))
                    .eq("id", value: existing.id.uuidString)
                    .select()
                    .single()
                    .execute()
                    .value
                upsertLocal(rating: updated)
            } else {
                let created: MealRating = try await supabase
                    .from("meal_ratings")
                    .insert(NewRating(mealID: mealID, raterID: userID, reaction: reaction, answers: answers))
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
            return true
        } catch {
            Self.log.error("Failed to save rating: \(error.localizedDescription, privacy: .public)")
            errorMessage = Self.describe(error)
            return false
        }
    }

    func myRating(forMeal mealID: UUID) -> Reaction? {
        ratings(forMeal: mealID).first { $0.raterID == userID }?.reaction
    }

    func ratings(for rater: RaterRef) -> [MealRating] {
        ratings.filter { rating in
            switch rater {
            case .eater(let id):
                return rating.eaterID == id
            case .account(let id):
                return rating.raterID == id
            }
        }
    }

    func rating(for rater: RaterRef, on mealID: UUID) -> MealRating? {
        ratings(forMeal: mealID).first { rating in
            switch rater {
            case .eater(let id):
                return rating.eaterID == id
            case .account(let id):
                return rating.raterID == id
            }
        }
    }

    /// Average taste reaction for a single meal based on all eaters' verdicts.
    func averageReaction(forMeal mealID: UUID) -> Reaction? {
        averageScore(forMeal: mealID).map(Reaction.init(score:))
    }

    /// Average rotation goal for a meal, falling back to dish average if not explicitly set.
    func averageRotation(forMeal mealID: UUID) -> RotationGoal? {
        if let meal = meal(mealID), let repeatDesire = meal.repeatDesire {
            return repeatDesire
        }
        guard let meal = meal(mealID) else { return nil }
        return averageRotation(forDish: meal.dishID)
    }

    /// Average rotation goal across all historical servings of a dish.
    func averageRotation(forDish dishID: UUID) -> RotationGoal? {
        let goals = servings(of: dishID).compactMap(\.repeatDesire)
        guard !goals.isEmpty else { return nil }
        let avg = Double(goals.map(\.rawValue).reduce(0, +)) / Double(goals.count)
        let rounded = Int(avg.rounded())
        return RotationGoal(rawValue: min(2, max(0, rounded)))
    }

    /// Average score across all historical servings of a dish (0.0 to 1.0).
    func averageScore(forDish dishID: UUID) -> Double? {
        let dishMeals = servings(of: dishID)
        let scores = dishMeals.compactMap { averageScore(forMeal: $0.id) }
        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / Double(scores.count)
    }

    /// Average taste reaction across all historical servings of a dish.
    func averageReaction(forDish dishID: UUID) -> Reaction? {
        averageScore(forDish: dishID).map(Reaction.init(score:))
    }

    /// Saves the chef's review and adjustments: actual cooking time/duration and chef cooking notes.
    func saveChefDetails(
        mealID: UUID,
        effort: EffortLevel?,
        notes: String
    ) async -> Bool {
        guard let currentMeal = meal(mealID) else { return false }
        do {
            struct ChefDetailsPatch: Encodable {
                let effort: Int?
                let notes: String
            }
            let patch = ChefDetailsPatch(effort: effort?.rawValue, notes: notes)
            let updatedMeal: Meal = try await supabase
                .from("meals")
                .update(patch)
                .eq("id", value: mealID.uuidString)
                .select()
                .single()
                .execute()
                .value
            upsertLocal(meal: updatedMeal)

            // Sync effort to dish if the dish doesn't have one and user is the cook
            if let effort, let dish = dish(currentMeal.dishID), dish.effort == nil, currentMeal.createdBy == userID {
                struct DishEffortPatch: Encodable {
                    let effort: Int?
                }
                let updatedDish: Dish = try await supabase
                    .from("dishes")
                    .update(DishEffortPatch(effort: effort.rawValue))
                    .eq("id", value: dish.id.uuidString)
                    .select()
                    .single()
                    .execute()
                    .value
                upsertLocal(dish: updatedDish)
            }

            reindex()
            errorMessage = nil
            return true
        } catch {
            Self.log.error("Failed to save chef details: \(error.localizedDescription, privacy: .public)")
            errorMessage = Self.describe(error)
            return false
        }
    }
}
