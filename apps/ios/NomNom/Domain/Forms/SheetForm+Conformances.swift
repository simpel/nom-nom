import Foundation

// Existing values that edit sheets work on directly.

extension FoodStore.MealDraft: SheetForm {
    var isValid: Bool { !recipeName.trimmedName.isEmpty }
}

extension RatingAnswers: SheetForm {
    /// The verdict is required; everything else is optional.
    var isValid: Bool { reaction != nil }
}

extension RecipeFilterCriteria: SheetForm {}

extension RecipeIngredient: SheetForm {
    var isValid: Bool { !trimmedIngredient.isEmpty }
}

/// A group's name is optional, so any value can be saved.
extension IngredientGroup: SheetForm {}
