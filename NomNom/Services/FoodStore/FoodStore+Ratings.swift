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
        guard let score = averageScore(forMeal: mealID) else { return nil }
        if score >= 0.85 { return .amazing }
        if score >= 0.70 { return .great }
        if score >= 0.50 { return .good }
        if score >= 0.30 { return .meh }
        if score >= 0.15 { return .bad }
        return .inedible
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

    /// Average taste reaction across all historical servings of a dish.
    func averageReaction(forDish dishID: UUID) -> Reaction? {
        let dishMeals = servings(of: dishID)
        let scores = dishMeals.compactMap { averageScore(forMeal: $0.id) }
        guard !scores.isEmpty else { return nil }
        let avgScore = scores.reduce(0, +) / Double(scores.count)
        if avgScore >= 0.85 { return .amazing }
        if avgScore >= 0.70 { return .great }
        if avgScore >= 0.50 { return .good }
        if avgScore >= 0.30 { return .meh }
        if avgScore >= 0.15 { return .bad }
        return .inedible
    }

    /// Saves an eater's evaluation of a meal: taste verdict, rotation goal, and eater notes.
    func saveEaterRating(
        mealID: UUID,
        verdicts: [RaterRef: Reaction],
        repeatDesire: RotationGoal?,
        notes: String? = nil
    ) async -> Bool {
        guard let currentMeal = meal(mealID) else { return false }
        do {
            // 1. Update verdicts (ratings for me and household eaters)
            try await applyVerdicts(verdicts, to: currentMeal)

            // 2. Update rotation goal on the meal if changed
            struct MealRotationPatch: Encodable {
                let repeat_desire: Int?
            }
            if currentMeal.repeatDesire != repeatDesire {
                let patch = MealRotationPatch(repeat_desire: repeatDesire?.rawValue)
                let updatedMeal: Meal = try await supabase
                    .from("meals")
                    .update(patch)
                    .eq("id", value: mealID.uuidString)
                    .select()
                    .single()
                    .execute()
                    .value
                upsertLocal(meal: updatedMeal)
            }

            // 3. Accept pending invite if applicable
            if let invite = invites.first(where: { $0.mealID == mealID && $0.inviteeID == userID }),
               invite.status != .accepted {
                try await setInviteStatus(invite, to: .accepted)
            }

            reindex()
            errorMessage = nil
            return true
        } catch {
            Self.log.error("Failed to save eater rating: \(error.localizedDescription, privacy: .public)")
            errorMessage = Self.describe(error)
            return false
        }
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

    /// Backwards-compatible convenience method.
    func saveRating(
        mealID: UUID,
        verdicts: [RaterRef: Reaction],
        repeatDesire: RotationGoal?,
        effort: EffortLevel?,
        notes: String? = nil
    ) async -> Bool {
        let ok1 = await saveEaterRating(mealID: mealID, verdicts: verdicts, repeatDesire: repeatDesire, notes: notes)
        if let effort {
            _ = await saveChefDetails(mealID: mealID, effort: effort, notes: notes ?? "")
        }
        return ok1
    }
}
