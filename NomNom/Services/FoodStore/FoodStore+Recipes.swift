import Foundation
import Supabase

extension FoodStore {

    func findOrCreateRecipe(
        named name: String,
        tags: [String] = [],
        cuisine: String? = nil,
        isPublic: Bool = true
    ) async throws -> Recipe {
        let key = name.normalizedForMatching

        if let existing = myRecipes.first(where: { $0.normalizedName == key }) {
            if !tags.isEmpty { try await addTags(tags, to: existing) }
            return existing
        }

        do {
            let created: Recipe = try await supabase
                .from("dishes")
                .insert(NewRecipe(
                    ownerID: userID,
                    name: name,
                    tags: tags,
                    cuisine: cuisine,
                    isPublic: isPublic
                ))
                .select()
                .single()
                .execute()
                .value
            recipes.append(created)
            reindex()
            return created
        } catch let error as PostgrestError where error.code == "23505" {
            let raced: Recipe = try await supabase
                .from("dishes")
                .select()
                .eq("owner_id", value: userID.uuidString)
                .eq("normalized_name", value: key)
                .single()
                .execute()
                .value
            upsertLocal(recipe: raced)
            if !tags.isEmpty { try await addTags(tags, to: raced) }
            return raced
        }
    }

    func addTags(_ tags: [String], to recipe: Recipe) async throws {
        let merged = Array(Set(recipe.tags).union(tags)).sorted()
        guard merged != recipe.tags else { return }
        let updated: Recipe = try await supabase
            .from("dishes")
            .update(RecipeTagsPatch(tags: merged))
            .eq("id", value: recipe.id.uuidString)
            .select()
            .single()
            .execute()
            .value
        upsertLocal(recipe: updated)
    }

    func rename(recipe: Recipe, to newName: String) async {
        let trimmed = newName.trimmedName
        guard !trimmed.isEmpty, trimmed != recipe.name else { return }
        do {
            let updated: Recipe = try await supabase
                .from("dishes")
                .update(RecipeNamePatch(name: trimmed))
                .eq("id", value: recipe.id.uuidString)
                .select()
                .single()
                .execute()
                .value
            upsertLocal(recipe: updated)
            errorMessage = nil
        } catch let error as PostgrestError where error.code == "23505" {
            errorMessage = "You already have a recipe called “\(trimmed)”. Merge them instead."
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func applyRecipe(_ draft: RecipeDraft, to recipe: Recipe) async throws {
        let effortToSave = draft.effort ?? recipe.effort
        let cuisineToSave = draft.cuisine ?? recipe.cuisine
        let isPublicToSave = draft.isPublic
        let updatedText = draft.text.trimmingCharacters(in: .whitespacesAndNewlines)

        for path in draft.removedPhotoPaths {
            await deleteRecipeObject(path)
        }
        var newPaths = draft.existingPhotoPaths
        for data in draft.addedPhotoData {
            let path = "\(recipe.id.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
            _ = try await supabase.storage
                .from(SupabaseConfig.recipeBucket)
                .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
            PhotoCache.shared.put(data, for: path)
            newPaths.append(path)
        }

        guard recipe.recipeText != updatedText ||
              recipe.recipePhotoPaths != newPaths ||
              recipe.effort != effortToSave ||
              recipe.cuisine != cuisineToSave ||
              recipe.isPublic != isPublicToSave else { return }

        let updated: Recipe = try await supabase
            .from("dishes")
            .update(RecipeContentPatch(
                recipe_text: updatedText,
                recipe_photo_paths: newPaths,
                effort: effortToSave,
                cuisine: cuisineToSave,
                isPublic: isPublicToSave
            ))
            .eq("id", value: recipe.id.uuidString)
            .select()
            .single()
            .execute()
            .value
        upsertLocal(recipe: updated)
    }

    func deleteRecipeObject(_ path: String) async {
        PhotoCache.shared.forget(path)
        do {
            _ = try await supabase.storage.from(SupabaseConfig.recipeBucket).remove(paths: [path])
        } catch {
            Self.log.error("could not remove recipe photo \(path, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    func merge(recipe source: Recipe, into target: Recipe) async {
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
            for path in source.recipePhotoPaths {
                await deleteRecipeObject(path)
            }
            try await supabase
                .from("dishes")
                .delete()
                .eq("id", value: source.id.uuidString)
                .execute()

            for index in meals.indices where meals[index].recipeID == source.id {
                meals[index].recipeID = target.id
            }
            recipes.removeAll { $0.id == source.id }
            reindex()
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    // MARK: - Photos

    func photos(for recipeID: UUID) -> [String] {
        var paths: [String] = []
        let history = servings(of: recipeID).sorted { $0.eatenOn > $1.eatenOn }
        for meal in history {
            for p in meal.photoPaths where !paths.contains(p) {
                paths.append(p)
            }
        }
        if let recipe = recipe(recipeID) {
            for p in recipe.recipePhotoPaths where !paths.contains(p) {
                paths.append(p)
            }
        }
        return paths
    }

    func photos(for recipe: Recipe) -> [String] {
        photos(for: recipe.id)
    }

    // MARK: - Discovery & Ranking Helpers

    var popularRecipes: [Recipe] {
        recipes.sorted { lhs, rhs in
            let lCount = servings(of: lhs.id).count
            let rCount = servings(of: rhs.id).count
            if lCount != rCount { return lCount > rCount }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    var recentRecipes: [Recipe] {
        recipes
            .compactMap { recipe -> (Recipe, Date)? in
                guard let last = servings(of: recipe.id).map(\.eatenOn).max() else { return nil }
                return (recipe, last)
            }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    // MARK: - Compatibility Wrappers

    func findOrCreateDish(named name: String, tags: [String]) async throws -> Recipe {
        try await findOrCreateRecipe(named: name, tags: tags)
    }

    func rename(dish: Recipe, to newName: String) async {
        await rename(recipe: dish, to: newName)
    }

    func merge(dish source: Recipe, into target: Recipe) async {
        await merge(recipe: source, into: target)
    }
}
