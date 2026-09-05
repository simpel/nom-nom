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
        guard recipe.ownerID == userID else { return }
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
        guard recipe.ownerID == userID else { return }
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
            errorMessage = "You already have a recipe called “\(trimmed)”."
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func applyRecipe(_ draft: RecipeDraft, to recipe: Recipe) async throws {
        guard recipe.ownerID == userID else { return }
        let effortToSave = draft.effort ?? recipe.effort
        let cuisineToSave = draft.cuisine ?? recipe.cuisine
        let isPublicToSave = draft.isPublic
        let cleanIngredients = draft.ingredients.filter { !$0.isEmpty }
        let cleanInstructions = draft.instructions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for path in draft.removedPhotoPaths {
            await deleteRecipeObject(path)
        }
        var newPaths: [String] = []
        for p in draft.existingPhotoPaths where !newPaths.contains(p) {
            newPaths.append(p)
        }
        for data in draft.addedPhotoData {
            let path = "\(recipe.id.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
            _ = try await supabase.storage
                .from(SupabaseConfig.recipeBucket)
                .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
            PhotoCache.shared.put(data, for: path)
            if !newPaths.contains(path) {
                newPaths.append(path)
            }
        }

        guard recipe.ingredients != cleanIngredients ||
              recipe.instructions != cleanInstructions ||
              recipe.recipePhotoPaths != newPaths ||
              recipe.effort != effortToSave ||
              recipe.cuisine != cuisineToSave ||
              recipe.isPublic != isPublicToSave else { return }

        let updated: Recipe = try await supabase
            .from("dishes")
            .update(RecipeContentPatch(
                ingredients: cleanIngredients,
                instructions: cleanInstructions,
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

    func applyCoverPhotos(_ draft: PhotosDraft, to recipe: Recipe) async throws {
        guard recipe.ownerID == userID else { return }
        for path in draft.removedPaths {
            await deleteRecipeObject(path)
        }

        var newPaths: [String] = []
        for item in draft.items {
            switch item {
            case .existing(let path):
                if !newPaths.contains(path) {
                    newPaths.append(path)
                }
            case .added(_, let data):
                let path = "\(recipe.id.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
                _ = try await supabase.storage
                    .from(SupabaseConfig.recipeBucket)
                    .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
                PhotoCache.shared.put(data, for: path)
                if !newPaths.contains(path) {
                    newPaths.append(path)
                }
            }
        }

        if newPaths != recipe.photoPaths {
            let updated: Recipe = try await supabase
                .from("dishes")
                .update(RecipePhotosPatch(photo_paths: newPaths))
                .eq("id", value: recipe.id.uuidString)
                .select()
                .single()
                .execute()
                .value
            upsertLocal(recipe: updated)
        }
    }

    // MARK: - Photos

    func photos(for recipeID: UUID) -> [String] {
        var paths: [String] = []
        if let recipe = recipe(recipeID) {
            for p in recipe.photoPaths where !paths.contains(p) {
                paths.append(p)
            }
            for p in recipe.recipePhotoPaths where !paths.contains(p) {
                paths.append(p)
            }
        }
        return paths
    }

    func photos(for recipe: Recipe) -> [String] {
        photos(for: recipe.id)
    }



    func delete(recipe: Recipe) async {
        guard recipe.ownerID == userID else { return }
        do {
            for path in recipe.photoPaths { await deleteRecipeObject(path) }
            for path in recipe.recipePhotoPaths { await deleteRecipeObject(path) }
            try await supabase.from("dishes").delete().eq("id", value: recipe.id.uuidString).execute()
            recipes.removeAll { $0.id == recipe.id }
            reindex()
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    // MARK: - Compatibility Wrappers

    func findOrCreateDish(named name: String, tags: [String]) async throws -> Recipe {
        try await findOrCreateRecipe(named: name, tags: tags)
    }

    func rename(dish: Recipe, to newName: String) async {
        await rename(recipe: dish, to: newName)
    }

    func delete(dish: Recipe) async {
        await delete(recipe: dish)
    }
}
