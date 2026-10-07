import Foundation

/// A recipe while it is created or edited: its name, cover photos and the recipe
/// itself. Edited by CreateRecipeSheet and RecipeEditSheet (then RecipeDetailsStepView),
/// and by DishRecipeEditSheet inside the meal editor.
struct RecipeForm: SheetForm {
    var name: String = ""
    var coverPhotos = FoodStore.PhotosDraft()
    var recipe = FoodStore.RecipeDraft()

    var isValid: Bool { !name.trimmedName.isEmpty }
}

extension RecipeForm {
    /// A new recipe, optionally prefilled with a name and cuisine.
    init(name: String, cuisine: String?) {
        self.name = name
        recipe.cuisine = cuisine
    }

    /// An existing recipe as it is saved.
    init(_ recipe: Recipe) {
        name = recipe.name
        coverPhotos = FoodStore.PhotosDraft(existingPaths: recipe.photoPaths)
        self.recipe = FoodStore.RecipeDraft(
            ingredients: recipe.ingredients,
            instructions: recipe.instructions,
            existingPhotoPaths: recipe.recipePhotoPaths,
            addedPhotoData: [],
            removedPhotoPaths: [],
            effort: recipe.effort,
            cuisine: recipe.cuisine,
            cuisineID: recipe.cuisineID,
            cookingMethodID: recipe.cookingMethodID,
            dishKindID: recipe.dishKindID,
            isPublic: recipe.isPublic
        )
    }
}
