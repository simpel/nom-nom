import Foundation

/// A recipe is the canonical *name* and cooking guide for something we cook.
/// Every time we cook it we add a `Meal` that points back here.
///
/// `normalizedName` is the folded matching key, and the database's
/// `unique (owner_id, normalized_name)` prevents duplicate recipes.
struct Recipe: Identifiable, Hashable, Decodable {
    let id: UUID
    var ownerID: UUID?
    /// The name as the user typed it (display form).
    var name: String
    /// Lowercased, diacritic-folded, whitespace-collapsed. Used for matching.
    var normalizedName: String
    /// Structured ingredients list (each with quantity, measurement, and ingredient).
    var ingredients: [RecipeIngredient]
    /// Step-by-step preparation instructions.
    var instructions: [String]
    /// Cook mode's per-step timers and ingredients, aligned with `instructions`.
    var instructionDetails: [RecipeStepDetail]?
    /// Paths to dish cover photos in `recipe-photos` storage bucket.
    var photoPaths: [String]
    /// Primary cover photo path.
    var photoPath: String? { photoPaths.first }
    /// Paths to recipe images in `recipe-photos` storage bucket.
    var recipePhotoPaths: [String]
    /// Effort required to prep and cook this recipe.
    var effort: EffortLevel?
    /// Kitchen / cuisine classification (e.g. "asian", "mexican", "italian").
    var cuisine: String?
    /// Universal taxonomy reference to cuisine.
    var cuisineID: UUID?
    /// Primary cooking method reference.
    var cookingMethodID: UUID?
    /// Number of servings / portions this recipe yields.
    var serves: Int?
    /// Nutritional health index score (1–100).
    var healthScore: Int?
    /// Nutritional health qualitative verdict.
    var healthVerdict: String?
    /// Scientific nutritional explanation.
    var healthRationale: String?
    /// Structured nutritional strengths and cooking impact.
    var healthBreakdown: HealthBreakdown?
    /// LLM-normalized core ingredient categories from the health analysis pass (see
    /// `HealthIndex.canonicalIngredients`). Empty until the recipe has been analyzed.
    var canonicalIngredients: [String]
    /// Universal taxonomy reference to dish_kind (e.g. stew, soup, pasta).
    var dishKindID: UUID?
    /// Whether the recipe is public and visible to other dinner parties.
    var isPublic: Bool
    var isDeleted: Bool
    var createdAt: Date

    var healthIndex: HealthIndex? {
        guard let score = healthScore, let verdict = healthVerdict, let rationale = healthRationale else {
            return nil
        }
        return HealthIndex(
            score: score,
            verdict: verdict,
            rationale: rationale,
            breakdown: healthBreakdown,
            canonicalIngredients: canonicalIngredients
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name
        case normalizedName = "normalized_name"
        case ingredients
        case instructions
        case instructionDetails = "instruction_details"
        case photoPaths = "photo_paths"
        case recipePhotoPaths = "recipe_photo_paths"
        case effort
        case cuisine
        case cuisineID = "cuisine_id"
        case cookingMethodID = "cooking_method_id"
        case serves
        case healthScore = "health_score"
        case healthVerdict = "health_verdict"
        case healthRationale = "health_rationale"
        case healthBreakdown = "health_breakdown"
        case canonicalIngredients = "canonical_ingredients"
        case dishKindID = "dish_kind_id"
        case isPublic = "is_public"
        case isDeleted = "is_deleted"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        ownerID = try container.decodeIfPresent(UUID.self, forKey: .ownerID)
        name = try container.decode(String.self, forKey: .name)
        normalizedName = try container.decode(String.self, forKey: .normalizedName)
        ingredients = try container.decodeIfPresent([RecipeIngredient].self, forKey: .ingredients) ?? []
        instructions = try container.decodeIfPresent([String].self, forKey: .instructions) ?? []
        instructionDetails = try? container.decodeIfPresent([RecipeStepDetail].self, forKey: .instructionDetails)
        photoPaths = try container.decodeIfPresent([String].self, forKey: .photoPaths) ?? []
        recipePhotoPaths = try container.decodeIfPresent([String].self, forKey: .recipePhotoPaths) ?? []
        if let rawEffort = try container.decodeIfPresent(Int.self, forKey: .effort) {
            effort = EffortLevel(rawValue: rawEffort)
        } else {
            effort = nil
        }
        cuisine = try container.decodeIfPresent(String.self, forKey: .cuisine)
        cuisineID = try container.decodeIfPresent(UUID.self, forKey: .cuisineID)
        cookingMethodID = try container.decodeIfPresent(UUID.self, forKey: .cookingMethodID)
        serves = try container.decodeIfPresent(Int.self, forKey: .serves)
        healthScore = try container.decodeIfPresent(Int.self, forKey: .healthScore)
        healthVerdict = try container.decodeIfPresent(String.self, forKey: .healthVerdict)
        healthRationale = try container.decodeIfPresent(String.self, forKey: .healthRationale)
        healthBreakdown = try container.decodeIfPresent(HealthBreakdown.self, forKey: .healthBreakdown)
        canonicalIngredients = try container.decodeIfPresent([String].self, forKey: .canonicalIngredients) ?? []
        dishKindID = try container.decodeIfPresent(UUID.self, forKey: .dishKindID)
        isPublic = try container.decodeIfPresent(Bool.self, forKey: .isPublic) ?? true
        isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
        createdAt = try container.decodeTimestamp(.createdAt)
    }

    init(
        id: UUID = UUID(),
        ownerID: UUID?,
        name: String,
        normalizedName: String? = nil,
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
        canonicalIngredients: [String] = [],
        dishKindID: UUID? = nil,
        isPublic: Bool = true,
        isDeleted: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.ownerID = ownerID
        self.name = name.trimmedName
        self.normalizedName = normalizedName ?? name.normalizedForMatching
        self.ingredients = ingredients
        self.instructions = instructions
        self.photoPaths = photoPaths
        self.recipePhotoPaths = recipePhotoPaths
        self.effort = effort
        self.cuisine = cuisine
        self.cuisineID = cuisineID
        self.cookingMethodID = cookingMethodID
        self.serves = serves
        self.healthScore = healthScore
        self.healthVerdict = healthVerdict
        self.healthRationale = healthRationale
        self.healthBreakdown = healthBreakdown
        self.canonicalIngredients = canonicalIngredients
        self.dishKindID = dishKindID
        self.isPublic = isPublic
        self.isDeleted = isDeleted
        self.createdAt = createdAt
    }

    var hasInstructions: Bool {
        !ingredients.isEmpty || !instructions.isEmpty || !recipePhotoPaths.isEmpty
    }

    var hasRecipe: Bool { hasInstructions }
}

typealias Dish = Recipe

