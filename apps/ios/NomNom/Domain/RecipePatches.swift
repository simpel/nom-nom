import Foundation

/// Insert payload for Supabase `dishes` table.
struct NewRecipe: Encodable {
    let owner_id: UUID
    let name: String
    let normalized_name: String
    let ingredients: [RecipeIngredient]
    let instructions: [String]
    let photo_paths: [String]
    let recipe_photo_paths: [String]
    let effort: Int?
    let cuisine: String?
    let cuisine_id: UUID?
    let cooking_method_id: UUID?
    let serves: Int?
    let health_score: Int?
    let health_verdict: String?
    let health_rationale: String?
    let health_breakdown: HealthBreakdown?
    let dish_kind_id: UUID?
    let is_public: Bool

    init(
        ownerID: UUID,
        name: String,
        ingredients: [RecipeIngredient] = [],
        instructions: [String] = [],
        photoPaths: [String] = [],
        recipePhotoPaths: [String] = [],
        effort: EffortLevel? = nil,
        cuisine: String? = nil,
        cuisineID: UUID? = nil,
        cookingMethodID: UUID? = nil,
        serves: Int? = nil,
        healthScore: Int? = nil,
        healthVerdict: String? = nil,
        healthRationale: String? = nil,
        healthBreakdown: HealthBreakdown? = nil,
        dishKindID: UUID? = nil,
        isPublic: Bool = true
    ) {
        self.owner_id = ownerID
        self.name = name.trimmedName
        self.normalized_name = name.normalizedForMatching
        self.ingredients = ingredients
        self.instructions = instructions
        self.photo_paths = photoPaths
        self.recipe_photo_paths = recipePhotoPaths
        self.effort = effort?.rawValue
        self.cuisine = cuisine?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? cuisine : nil
        self.cuisine_id = cuisineID
        self.cooking_method_id = cookingMethodID
        self.serves = serves
        self.health_score = healthScore
        self.health_verdict = healthVerdict
        self.health_rationale = healthRationale
        self.health_breakdown = healthBreakdown
        self.dish_kind_id = dishKindID
        self.is_public = isPublic
    }
}

/// Patch for a recipe rename.
struct RecipeNamePatch: Encodable {
    let name: String
    let normalized_name: String

    init(name: String) {
        self.name = name.trimmedName
        self.normalized_name = name.normalizedForMatching
    }
}

/// Patch for recipe cover photos.
struct RecipePhotosPatch: Encodable {
    let photo_paths: [String]
}

struct RecipeContentPatch: Encodable {
    let ingredients: [RecipeIngredient]
    let instructions: [String]
    let recipe_photo_paths: [String]
    let effort: Int?
    let cuisine: String?
    let cuisine_id: UUID?
    let cooking_method_id: UUID?
    let serves: Int?
    let is_public: Bool
    let health_score: Int?
    let health_verdict: String?
    let health_rationale: String?
    let health_breakdown: HealthBreakdown?
    let dish_kind_id: UUID?

    init(
        ingredients: [RecipeIngredient],
        instructions: [String],
        recipe_photo_paths: [String],
        effort: EffortLevel? = nil,
        cuisine: String? = nil,
        cuisineID: UUID? = nil,
        cookingMethodID: UUID? = nil,
        serves: Int? = nil,
        isPublic: Bool = true,
        healthScore: Int? = nil,
        healthVerdict: String? = nil,
        healthRationale: String? = nil,
        healthBreakdown: HealthBreakdown? = nil,
        dishKindID: UUID? = nil
    ) {
        self.ingredients = ingredients
        self.instructions = instructions
        self.recipe_photo_paths = recipe_photo_paths
        self.effort = effort?.rawValue
        self.cuisine = cuisine?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? cuisine : nil
        self.cuisine_id = cuisineID
        self.cooking_method_id = cookingMethodID
        self.serves = serves
        self.is_public = isPublic
        self.health_score = healthScore
        self.health_verdict = healthVerdict
        self.health_rationale = healthRationale
        self.health_breakdown = healthBreakdown
        self.dish_kind_id = dishKindID
    }
}

/// Patch for updating recipe health score and rationale.
struct RecipeHealthPatch: Encodable {
    let health_score: Int?
    let health_verdict: String?
    let health_rationale: String?
    let health_breakdown: HealthBreakdown?
    let canonical_ingredients: [String]?
}
