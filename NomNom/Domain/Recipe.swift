import Foundation

/// A recipe is the canonical *name* and cooking guide for something we cook.
/// Every time we cook it we add a `Meal` that points back here.
///
/// `normalizedName` is the folded matching key, and the database's
/// `unique (owner_id, normalized_name)` prevents duplicate recipes.
struct Recipe: Identifiable, Hashable, Decodable {
    let id: UUID
    var ownerID: UUID
    /// The name as the user typed it (display form).
    var name: String
    /// Lowercased, diacritic-folded, whitespace-collapsed. Used for matching.
    var normalizedName: String
    /// Optional free-form tags, e.g. "quick", "oven", "veggie".
    var tags: [String]
    /// Structured ingredients list (each with quantity, measurement, and ingredient).
    var ingredients: [RecipeIngredient]
    /// Step-by-step preparation instructions.
    var instructions: [String]
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
    /// Whether the recipe is public and visible to other dinner parties.
    var isPublic: Bool
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name
        case normalizedName = "normalized_name"
        case tags
        case ingredients
        case instructions
        case photoPaths = "photo_paths"
        case recipePhotoPaths = "recipe_photo_paths"
        case effort
        case cuisine
        case isPublic = "is_public"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        ownerID = try container.decode(UUID.self, forKey: .ownerID)
        name = try container.decode(String.self, forKey: .name)
        normalizedName = try container.decode(String.self, forKey: .normalizedName)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        ingredients = try container.decodeIfPresent([RecipeIngredient].self, forKey: .ingredients) ?? []
        instructions = try container.decodeIfPresent([String].self, forKey: .instructions) ?? []
        photoPaths = try container.decodeIfPresent([String].self, forKey: .photoPaths) ?? []
        recipePhotoPaths = try container.decodeIfPresent([String].self, forKey: .recipePhotoPaths) ?? []
        if let rawEffort = try container.decodeIfPresent(Int.self, forKey: .effort) {
            effort = EffortLevel(rawValue: rawEffort)
        } else {
            effort = nil
        }
        cuisine = try container.decodeIfPresent(String.self, forKey: .cuisine)
        isPublic = try container.decodeIfPresent(Bool.self, forKey: .isPublic) ?? true
        createdAt = try container.decodeTimestamp(.createdAt)
    }

    init(
        id: UUID = UUID(),
        ownerID: UUID,
        name: String,
        normalizedName: String? = nil,
        tags: [String] = [],
        ingredients: [RecipeIngredient] = [],
        instructions: [String] = [],
        photoPaths: [String] = [],
        recipePhotoPaths: [String] = [],
        effort: EffortLevel? = nil,
        cuisine: String? = nil,
        isPublic: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.ownerID = ownerID
        self.name = name.trimmedName
        self.normalizedName = normalizedName ?? name.normalizedForMatching
        self.tags = tags
        self.ingredients = ingredients
        self.instructions = instructions
        self.photoPaths = photoPaths
        self.recipePhotoPaths = recipePhotoPaths
        self.effort = effort
        self.cuisine = cuisine
        self.isPublic = isPublic
        self.createdAt = createdAt
    }

    var hasInstructions: Bool {
        !ingredients.isEmpty || !instructions.isEmpty || !recipePhotoPaths.isEmpty
    }

    var hasRecipe: Bool { hasInstructions }
}

typealias Dish = Recipe

// MARK: - Writes

/// Insert payload for Supabase `dishes` table.
struct NewRecipe: Encodable {
    let owner_id: UUID
    let name: String
    let normalized_name: String
    let tags: [String]
    let ingredients: [RecipeIngredient]
    let instructions: [String]
    let photo_paths: [String]
    let recipe_photo_paths: [String]
    let effort: Int?
    let cuisine: String?
    let is_public: Bool

    init(
        ownerID: UUID,
        name: String,
        tags: [String] = [],
        ingredients: [RecipeIngredient] = [],
        instructions: [String] = [],
        photoPaths: [String] = [],
        recipePhotoPaths: [String] = [],
        effort: EffortLevel? = nil,
        cuisine: String? = nil,
        isPublic: Bool = true
    ) {
        self.owner_id = ownerID
        self.name = name.trimmedName
        self.normalized_name = name.normalizedForMatching
        self.tags = tags
        self.ingredients = ingredients
        self.instructions = instructions
        self.photo_paths = photoPaths
        self.recipe_photo_paths = recipePhotoPaths
        self.effort = effort?.rawValue
        self.cuisine = cuisine?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? cuisine : nil
        self.is_public = isPublic
    }
}

typealias NewDish = NewRecipe

/// Patch for a recipe rename.
struct RecipeNamePatch: Encodable {
    let name: String
    let normalized_name: String

    init(name: String) {
        self.name = name.trimmedName
        self.normalized_name = name.normalizedForMatching
    }
}

typealias DishNamePatch = RecipeNamePatch

struct RecipeTagsPatch: Encodable {
    let tags: [String]
}

typealias DishTagsPatch = RecipeTagsPatch

/// Patch for recipe cover photos.
struct RecipePhotosPatch: Encodable {
    let photo_paths: [String]
}

typealias DishPhotosPatch = RecipePhotosPatch

struct RecipeContentPatch: Encodable {
    let ingredients: [RecipeIngredient]
    let instructions: [String]
    let recipe_photo_paths: [String]
    let effort: Int?
    let cuisine: String?
    let is_public: Bool

    init(
        ingredients: [RecipeIngredient],
        instructions: [String],
        recipe_photo_paths: [String],
        effort: EffortLevel? = nil,
        cuisine: String? = nil,
        isPublic: Bool = true
    ) {
        self.ingredients = ingredients
        self.instructions = instructions
        self.recipe_photo_paths = recipe_photo_paths
        self.effort = effort?.rawValue
        self.cuisine = cuisine?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? cuisine : nil
        self.is_public = isPublic
    }
}

typealias DishRecipePatch = RecipeContentPatch

