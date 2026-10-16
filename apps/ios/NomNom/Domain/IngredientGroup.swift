import Foundation

/// A run of a recipe's ingredients that belong together ("Sauce", "Salad"), stored in
/// `recipes.ingredient_groups`. The name is optional: a recipe without sections is one
/// group with no name.
struct IngredientGroup: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String
    var ingredients: [RecipeIngredient]

    init(id: UUID = UUID(), name: String = "", ingredients: [RecipeIngredient] = []) {
        self.id = id
        self.name = name
        self.ingredients = ingredients
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The heading to show, or nil for an unnamed group.
    var title: String? {
        trimmedName.isEmpty ? nil : trimmedName
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case name
        case ingredients
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        ingredients = try container.decodeIfPresent([RecipeIngredient].self, forKey: .ingredients) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let title { try container.encode(title, forKey: .name) } else { try container.encodeNil(forKey: .name) }
        try container.encode(ingredients, forKey: .ingredients)
    }
}

extension Array where Element == IngredientGroup {
    /// Every ingredient in order (the first group's, then the next's). Cook mode's step
    /// indexes (`RecipeStepDetail.ingredients`) point into this list.
    var allIngredients: [RecipeIngredient] {
        flatMap(\.ingredients)
    }

    /// What is saved: empty ingredients dropped, then groups left with none.
    var cleaned: [IngredientGroup] {
        compactMap { group in
            var group = group
            group.ingredients.removeAll { $0.isEmpty }
            return group.ingredients.isEmpty ? nil : group
        }
    }

    /// True when only one unnamed group exists, so the list reads as plain ingredients.
    var isUngrouped: Bool {
        count <= 1 && first?.title == nil
    }
}
