import Foundation

/// A single recipe ingredient item with distinct quantity, measurement unit, and ingredient name.
struct RecipeIngredient: Identifiable, Hashable, Codable {
    var id: UUID
    var quantity: String
    var measurement: String
    var ingredient: String

    init(
        id: UUID = UUID(),
        quantity: String = "",
        measurement: String = "",
        ingredient: String = ""
    ) {
        self.id = id
        self.quantity = quantity
        self.measurement = measurement
        self.ingredient = ingredient
    }

    var isEmpty: Bool {
        quantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        measurement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        ingredient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var trimmedQuantity: String {
        quantity.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedMeasurement: String {
        measurement.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedIngredient: String {
        ingredient.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Combined display amount (e.g. "500 g", "2 tbsp", "1", or "pinch").
    var formattedAmount: String {
        let q = trimmedQuantity
        let m = trimmedMeasurement
        if q.isEmpty { return m }
        if m.isEmpty { return q }
        return "\(q) \(m)"
    }

    /// Full formatted line (e.g. "500 g flour" or "Salt & pepper").
    var formattedDescription: String {
        let amt = formattedAmount
        let ing = trimmedIngredient
        if amt.isEmpty { return ing }
        if ing.isEmpty { return amt }
        return "\(amt) \(ing)"
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case quantity
        case measurement
        case ingredient
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.quantity = try container.decodeIfPresent(String.self, forKey: .quantity) ?? ""
        self.measurement = try container.decodeIfPresent(String.self, forKey: .measurement) ?? ""
        self.ingredient = try container.decodeIfPresent(String.self, forKey: .ingredient) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trimmedQuantity, forKey: .quantity)
        try container.encode(trimmedMeasurement, forKey: .measurement)
        try container.encode(trimmedIngredient, forKey: .ingredient)
    }
}
