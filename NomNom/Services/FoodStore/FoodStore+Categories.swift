import Foundation
import Supabase

extension FoodStore {

    // MARK: - Category Management (Triggers in Supabase Handle Photos)

    struct NewCategoryPayload: Encodable {
        let slug: String
        let name: String
        let photo_path: String?
    }

    struct UpdateCategoryPayload: Encodable {
        let slug: String?
        let name: String?
        let photo_path: String?
        let updated_at: String
    }

    /// Creates a new culinary category in Postgres. Supabase DB triggers automatically generate its photo.
    @discardableResult
    func createCategory(name: String) async throws -> CategoryRecord {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "NomNom", code: 400, userInfo: [NSLocalizedDescriptionKey: "Category name cannot be empty"])
        }

        let slug = trimmed
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        if let existing = categories.first(where: { $0.slug.lowercased() == slug }) {
            return existing
        }

        let payload = NewCategoryPayload(slug: slug, name: trimmed, photo_path: nil)
        let inserted: CategoryRecord = try await supabase
            .from("categories")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value

        categories.append(inserted)
        return inserted
    }

    /// Updates category name/slug in Postgres. Supabase DB triggers automatically handle photo replacement.
    func updateCategory(id: UUID, newName: String) async throws {
        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }
        let oldCategory = categories[index]
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newSlug = trimmed
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        let slugChanged = oldCategory.slug != newSlug

        // If slug changed, clear local cache for the old path
        if slugChanged, let oldPath = oldCategory.photoPath {
            PhotoCache.shared.forget(oldPath)
            categoryPhotoPaths.removeValue(forKey: oldCategory.slug.lowercased())
        }

        // Update category record in database (setting photo_path to nil if slug changed triggers generation)
        let payload = UpdateCategoryPayload(
            slug: newSlug,
            name: trimmed,
            photo_path: slugChanged ? nil : oldCategory.photoPath,
            updated_at: ISO8601DateFormatter().string(from: .now)
        )

        let updated: CategoryRecord = try await supabase
            .from("categories")
            .update(payload)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value

        categories[index] = updated

        // Update any dishes that were using the old category name or slug
        if slugChanged {
            struct RecipeCuisinePatch: Encodable {
                let cuisine: String?
            }
            for dish in dishes where dish.ownerID == userID && (dish.cuisine?.lowercased() == oldCategory.slug.lowercased() || dish.cuisine == oldCategory.name) {
                if let updatedRecipe: Recipe = try? await supabase
                    .from("dishes")
                    .update(RecipeCuisinePatch(cuisine: trimmed))
                    .eq("id", value: dish.id.uuidString)
                    .select()
                    .single()
                    .execute()
                    .value {
                    upsertLocal(recipe: updatedRecipe)
                }
            }
        }
    }

    /// Deletes a category from Postgres. Supabase DB triggers automatically clean up the photo from storage.
    func deleteCategory(id: UUID) async throws {
        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }
        let category = categories[index]

        if let path = category.photoPath {
            PhotoCache.shared.forget(path)
        }
        categoryPhotoPaths.removeValue(forKey: category.slug.lowercased())

        // Delete from database — Postgres trigger 'category_photo_cleanup_trigger' deletes storage object
        try await supabase
            .from("categories")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()

        categories.remove(at: index)
    }
}
