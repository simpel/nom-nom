import Foundation
import Supabase

extension FoodStore {

    struct PhotosDraft: Equatable {
        enum Item: Equatable, Identifiable {
            case existing(path: String)
            case added(id: UUID, data: Data)

            var id: String {
                switch self {
                case .existing(let path): return "existing:\(path)"
                case .added(let id, _): return "added:\(id.uuidString)"
                }
            }
        }

        var items: [Item] = []
        var removedPaths: [String] = []

        init(items: [Item] = [], removedPaths: [String] = []) {
            self.items = items
            self.removedPaths = removedPaths
        }

        init(existingPaths: [String] = [], addedData: [Data] = [], removedPaths: [String] = []) {
            self.items = existingPaths.map { .existing(path: $0) } + addedData.map { .added(id: UUID(), data: $0) }
            self.removedPaths = removedPaths
        }

        var existingPaths: [String] {
            get {
                items.compactMap {
                    if case .existing(let path) = $0 { return path }
                    return nil
                }
            }
            set {
                let added = items.filter { if case .added = $0 { return true } else { return false } }
                items = newValue.map { .existing(path: $0) } + added
            }
        }

        var addedData: [Data] {
            get {
                items.compactMap {
                    if case .added(_, let data) = $0 { return data }
                    return nil
                }
            }
            set {
                let existing = items.filter { if case .existing = $0 { return true } else { return false } }
                items = existing + newValue.map { .added(id: UUID(), data: $0) }
            }
        }

        var isEmpty: Bool {
            items.isEmpty
        }

        var count: Int {
            items.count
        }

        mutating func move(from source: IndexSet, to destination: Int) {
            items.move(fromOffsets: source, toOffset: destination)
        }

        mutating func swap(_ i: Int, _ j: Int) {
            guard items.indices.contains(i), items.indices.contains(j) else { return }
            items.swapAt(i, j)
        }

        mutating func append(_ data: Data) {
            items.append(.added(id: UUID(), data: data))
        }

        mutating func remove(at index: Int) {
            guard items.indices.contains(index) else { return }
            let removed = items.remove(at: index)
            if case .existing(let path) = removed {
                removedPaths.append(path)
            }
        }
    }

    struct RecipeDraft: Equatable {
        var text: String = ""
        var existingPhotoPaths: [String] = []
        var addedPhotoData: [Data] = []
        var removedPhotoPaths: [String] = []
        var effort: EffortLevel? = nil
        var cuisine: String? = nil
        var isPublic: Bool = true

        var totalPhotosCount: Int {
            existingPhotoPaths.count + addedPhotoData.count
        }

        var hasContent: Bool {
            if effort != nil || cuisine != nil || !isPublic { return true }
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || totalPhotosCount > 0
        }
    }

    struct MealDraft {
        var mealID: UUID?
        var dishName: String
        var linkedDishID: UUID?
        var eatenOn: Date
        var notes: String
        var tags: [String]
        var photos: PhotosDraft = PhotosDraft()
        var effort: EffortLevel? = nil
        var repeatDesire: RotationGoal? = nil
        var verdicts: [RaterRef: Reaction]
        var servedParties: Set<UUID>? = nil
        var recipe: RecipeDraft? = nil
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

            if let recipeDraft = draft.recipe, dish.ownerID == userID {
                try await applyRecipe(recipeDraft, to: dish)
            }

            let meal: Meal
            if let id = draft.mealID {
                meal = try await supabase
                    .from("meals")
                    .update(MealPatch(dishID: dish.id, eatenOn: draft.eatenOn, notes: draft.notes, effort: draft.effort, repeatDesire: draft.repeatDesire))
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
                                    notes: draft.notes,
                                    effort: draft.effort,
                                    repeatDesire: draft.repeatDesire))
                    .select()
                    .single()
                    .execute()
                    .value
            }
            upsertLocal(meal: meal)

            try await applyPhotos(draft.photos, to: meal)
            try await applyVerdicts(draft.verdicts, to: meal)
            if let servedParties = draft.servedParties {
                try await applyMealParties(servedParties, to: meal.id)
            }

            reindex()
            errorMessage = nil
            return true
        } catch {
            Self.log.error("Failed to save meal: \(error.localizedDescription, privacy: .public) - \(error)")
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

    func applyPhotos(_ draft: PhotosDraft, to meal: Meal) async throws {
        for path in draft.removedPaths {
            await deleteObject(path)
        }

        var newPaths: [String] = []
        for item in draft.items {
            switch item {
            case .existing(let path):
                newPaths.append(path)
            case .added(_, let data):
                let path = "\(meal.id.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
                _ = try await supabase.storage
                    .from(SupabaseConfig.photoBucket)
                    .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
                PhotoCache.shared.put(data, for: path)
                newPaths.append(path)
            }
        }

        if newPaths != meal.photoPaths {
            let updated: Meal = try await supabase
                .from("meals")
                .update(MealPhotosPatch(photoPaths: newPaths))
                .eq("id", value: meal.id.uuidString)
                .select()
                .single()
                .execute()
                .value
            upsertLocal(meal: updated)
        }
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
            for path in meal.photoPaths { await deleteObject(path) }
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
