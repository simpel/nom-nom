import Foundation

/// The recipe editor's moves within a recipe's ingredient groups: an ingredient to
/// another ingredient's place (in its own group or another) or to the end of a group,
/// and a group to another position. Each changes the flattened order cook mode's step
/// indexes point into; saving `ingredient_groups` re-runs analyze-recipe-steps, which
/// rebuilds them.
extension Array where Element == IngredientGroup {
    /// The group and position of the ingredient with this id.
    func location(of ingredientID: UUID) -> (group: Int, index: Int)? {
        for g in indices {
            if let i = self[g].ingredients.firstIndex(where: { $0.id == ingredientID }) { return (g, i) }
        }
        return nil
    }

    /// Puts the ingredient where `targetID` is. In the same group it takes that place (so
    /// dragging down past a row lands after it); in another group it goes just before it.
    mutating func move(_ ingredientID: UUID, toPlaceOf targetID: UUID) {
        guard ingredientID != targetID,
              let from = location(of: ingredientID),
              let to = location(of: targetID) else { return }
        // Removing first shifts a later row up one, so the original index is "after it".
        let item = self[from.group].ingredients.remove(at: from.index)
        self[to.group].ingredients.insert(item, at: to.index)
    }

    /// Moves the ingredient to the end of a group (an empty one too). Already in that
    /// group, it stays where it is.
    mutating func move(_ ingredientID: UUID, toEndOf groupID: UUID) {
        guard let from = location(of: ingredientID),
              self[from.group].id != groupID,
              let target = firstIndex(where: { $0.id == groupID }) else { return }
        let item = self[from.group].ingredients.remove(at: from.index)
        self[target].ingredients.append(item)
    }

    /// Renames the group and moves it to `position` (clamped), or appends a new one.
    mutating func save(_ group: IngredientGroup, at position: Int) {
        guard let g = firstIndex(where: { $0.id == group.id }) else {
            append(group)
            return
        }
        var existing = remove(at: g)
        existing.name = group.name
        insert(existing, at: Swift.min(Swift.max(position, 0), count))
    }
}
