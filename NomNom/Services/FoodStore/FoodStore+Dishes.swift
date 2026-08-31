import Foundation
import Supabase

extension FoodStore {

    func findOrCreateDish(named name: String, tags: [String]) async throws -> Dish {
        let key = name.normalizedForMatching

        if let existing = myDishes.first(where: { $0.normalizedName == key }) {
            if !tags.isEmpty { try await addTags(tags, to: existing) }
            return existing
        }

        do {
            let created: Dish = try await supabase
                .from("dishes")
                .insert(NewDish(ownerID: userID, name: name, tags: tags))
                .select()
                .single()
                .execute()
                .value
            dishes.append(created)
            reindex()
            return created
        } catch let error as PostgrestError where error.code == "23505" {
            let raced: Dish = try await supabase
                .from("dishes")
                .select()
                .eq("owner_id", value: userID.uuidString)
                .eq("normalized_name", value: key)
                .single()
                .execute()
                .value
            upsertLocal(dish: raced)
            if !tags.isEmpty { try await addTags(tags, to: raced) }
            return raced
        }
    }

    func addTags(_ tags: [String], to dish: Dish) async throws {
        let merged = Array(Set(dish.tags).union(tags)).sorted()
        guard merged != dish.tags else { return }
        let updated: Dish = try await supabase
            .from("dishes")
            .update(DishTagsPatch(tags: merged))
            .eq("id", value: dish.id.uuidString)
            .select()
            .single()
            .execute()
            .value
        upsertLocal(dish: updated)
    }

    func rename(dish: Dish, to newName: String) async {
        let trimmed = newName.trimmedName
        guard !trimmed.isEmpty, trimmed != dish.name else { return }
        do {
            let updated: Dish = try await supabase
                .from("dishes")
                .update(DishNamePatch(name: trimmed))
                .eq("id", value: dish.id.uuidString)
                .select()
                .single()
                .execute()
                .value
            upsertLocal(dish: updated)
            errorMessage = nil
        } catch let error as PostgrestError where error.code == "23505" {
            errorMessage = "You already have a dish called “\(trimmed)”. Merge them instead."
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func merge(dish source: Dish, into target: Dish) async {
        guard source.id != target.id else { return }
        do {
            let moved = servings(of: source.id)
            if !moved.isEmpty {
                try await supabase
                    .from("meals")
                    .update(["dish_id": target.id.uuidString])
                    .eq("dish_id", value: source.id.uuidString)
                    .execute()
            }
            try await supabase
                .from("dishes")
                .delete()
                .eq("id", value: source.id.uuidString)
                .execute()

            for index in meals.indices where meals[index].dishID == source.id {
                meals[index].dishID = target.id
            }
            dishes.removeAll { $0.id == source.id }
            reindex()
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }
}
