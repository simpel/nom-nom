import Foundation
import Supabase

extension FoodStore {

    enum PhotoChange {
        case unchanged
        case replaced(Data)
        case removed
    }

    struct MealDraft {
        var mealID: UUID?
        var dishName: String
        var linkedDishID: UUID?
        var eatenOn: Date
        var notes: String
        var tags: [String]
        var photo: PhotoChange
        var verdicts: [RaterRef: Reaction]
        var servedParties: Set<UUID>? = nil
    }

    @discardableResult
    func save(_ draft: MealDraft) async -> Bool {
        do {
            let dish: Dish
            if let linked = draft.linkedDishID,
               let existing = dishByID[linked],
               existing.ownerID == userID,
               existing.normalizedName == draft.dishName.normalizedForMatching {
                dish = existing
                if !draft.tags.isEmpty { try await addTags(draft.tags, to: existing) }
            } else {
                dish = try await findOrCreateDish(named: draft.dishName, tags: draft.tags)
            }

            let meal: Meal
            if let id = draft.mealID {
                meal = try await supabase
                    .from("meals")
                    .update(MealPatch(dishID: dish.id, eatenOn: draft.eatenOn, notes: draft.notes))
                    .eq("id", value: id.uuidString)
                    .select()
                    .single()
                    .execute()
                    .value
            } else {
                meal = try await supabase
                    .from("meals")
                    .insert(NewMeal(dishID: dish.id,
                                    createdBy: userID,
                                    eatenOn: draft.eatenOn,
                                    notes: draft.notes))
                    .select()
                    .single()
                    .execute()
                    .value
            }
            upsertLocal(meal: meal)

            try await applyPhoto(draft.photo, to: meal)
            try await applyVerdicts(draft.verdicts, to: meal)
            if let servedParties = draft.servedParties {
                try await applyMealParties(servedParties, to: meal.id)
            }

            reindex()
            errorMessage = nil
            return true
        } catch {
            errorMessage = Self.describe(error)
            return false
        }
    }

    func applyMealParties(_ partyIDs: Set<UUID>, to mealID: UUID) async throws {
        let current = Set((mealPartiesByMeal[mealID] ?? []).map(\.partyID))
        let toAdd = partyIDs.subtracting(current)
        let toRemove = current.subtracting(partyIDs)

        if !toAdd.isEmpty {
            let newRows = toAdd.map { NewMealParty(meal_id: mealID, party_id: $0) }
            let created: [MealParty] = try await supabase
                .from("meal_parties")
                .insert(newRows)
                .select()
                .execute()
                .value
            mealParties.append(contentsOf: created)
        }

        if !toRemove.isEmpty {
            try await supabase
                .from("meal_parties")
                .delete()
                .eq("meal_id", value: mealID.uuidString)
                .in("party_id", values: toRemove.map(\.uuidString))
                .execute()
            mealParties.removeAll { $0.mealID == mealID && toRemove.contains($0.partyID) }
        }
    }

    func applyPhoto(_ change: PhotoChange, to meal: Meal) async throws {
        let previous = mealByID[meal.id]?.photoPath ?? meal.photoPath

        switch change {
        case .unchanged:
            return

        case .removed:
            guard previous != nil else { return }
            try await patchPhotoPath(nil, on: meal.id)
            if let previous { await deleteObject(previous) }

        case .replaced(let data):
            let path = "\(meal.id.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
            _ = try await supabase.storage
                .from(SupabaseConfig.photoBucket)
                .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
            try await patchPhotoPath(path, on: meal.id)
            PhotoCache.shared.put(data, for: path)
            if let previous, previous != path { await deleteObject(previous) }
        }
    }

    func patchPhotoPath(_ path: String?, on mealID: UUID) async throws {
        let updated: Meal = try await supabase
            .from("meals")
            .update(MealPhotoPatch(photo_path: path))
            .eq("id", value: mealID.uuidString)
            .select()
            .single()
            .execute()
            .value
        upsertLocal(meal: updated)
    }

    func deleteObject(_ path: String) async {
        PhotoCache.shared.forget(path)
        do {
            _ = try await supabase.storage.from(SupabaseConfig.photoBucket).remove(paths: [path])
        } catch {
            Self.log.error("could not remove \(path, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    func applyVerdicts(_ verdicts: [RaterRef: Reaction], to meal: Meal) async throws {
        let mineToManage = Set(myEaters.map(\.id))
        let existing = ratings(forMeal: meal.id).filter { rating in
            switch rating.source {
            case .eater(let id): return mineToManage.contains(id)
            case .account(let id): return id == userID
            }
        }

        var byRef = Dictionary(existing.map { ($0.source, $0) }, uniquingKeysWith: { first, _ in first })

        for (ref, reaction) in verdicts {
            if let current = byRef.removeValue(forKey: ref) {
                guard current.reaction != reaction else { continue }
                let updated: MealRating = try await supabase
                    .from("meal_ratings")
                    .update(RatingPatch(reaction: reaction.rawValue))
                    .eq("id", value: current.id.uuidString)
                    .select()
                    .single()
                    .execute()
                    .value
                upsertLocal(rating: updated)
            } else {
                let created: MealRating = try await supabase
                    .from("meal_ratings")
                    .insert(NewRating(mealID: meal.id, source: ref, reaction: reaction))
                    .select()
                    .single()
                    .execute()
                    .value
                upsertLocal(rating: created)
            }
        }

        for stale in byRef.values {
            try await supabase
                .from("meal_ratings")
                .delete()
                .eq("id", value: stale.id.uuidString)
                .execute()
            ratings.removeAll { $0.id == stale.id }
        }
    }

    func delete(meal: Meal) async {
        do {
            if let path = meal.photoPath { await deleteObject(path) }
            try await supabase.from("meals").delete().eq("id", value: meal.id.uuidString).execute()
            meals.removeAll { $0.id == meal.id }
            ratings.removeAll { $0.mealID == meal.id }
            invites.removeAll { $0.mealID == meal.id }
            mealParties.removeAll { $0.mealID == meal.id }
            reindex()
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }
}
