import Foundation
import Supabase

extension FoodStore {

    func addEater(name: String, emoji: String) async {
        let trimmed = name.trimmedName
        guard !trimmed.isEmpty else { return }
        do {
            let created: Eater = try await supabase
                .from("eaters")
                .insert(NewEater(owner_id: userID,
                                 name: trimmed,
                                 emoji: emoji,
                                 sort_index: (myEaters.map(\.sortIndex).max() ?? -1) + 1))
                .select()
                .single()
                .execute()
                .value
            eaters.append(created)
            reindex()
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func update(eater: Eater) async {
        do {
            let updated: Eater = try await supabase
                .from("eaters")
                .update(EaterPatch(name: eater.name.trimmedName,
                                   emoji: eater.emoji,
                                   is_active: eater.isActive,
                                   sort_index: eater.sortIndex))
                .eq("id", value: eater.id.uuidString)
                .select()
                .single()
                .execute()
                .value
            if let index = eaters.firstIndex(where: { $0.id == updated.id }) {
                eaters[index] = updated
            }
            reindex()
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func delete(eater: Eater) async {
        var deactivated = eater
        deactivated.isActive = false
        await update(eater: deactivated)
    }

    func reorderEaters(_ ordered: [Eater]) async {
        for (index, eater) in ordered.enumerated() where eater.sortIndex != index {
            var moved = eater
            moved.sortIndex = index
            await update(eater: moved)
        }
    }
}
