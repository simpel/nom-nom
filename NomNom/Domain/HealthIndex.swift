import SwiftUI

/// Estimated macronutrient distribution per serving.
struct MacroNutrients: Codable, Hashable, Equatable {
    var calories: Int?
    var proteinGrams: Double?
    var carbsGrams: Double?
    var fatGrams: Double?

    enum CodingKeys: String, CodingKey {
        case calories
        case proteinGrams = "protein_g"
        case carbsGrams = "carbs_g"
        case fatGrams = "fat_g"
    }

    init(
        calories: Int? = nil,
        proteinGrams: Double? = nil,
        carbsGrams: Double? = nil,
        fatGrams: Double? = nil
    ) {
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intVal = try? container.decodeIfPresent(Int.self, forKey: .calories) {
            calories = intVal
        } else if let dblVal = try? container.decodeIfPresent(Double.self, forKey: .calories) {
            calories = Int(dblVal)
        } else {
            calories = nil
        }

        if let dbl = try? container.decodeIfPresent(Double.self, forKey: .proteinGrams) {
            proteinGrams = dbl
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .proteinGrams) {
            proteinGrams = Double(intVal)
        } else {
            proteinGrams = nil
        }

        if let dbl = try? container.decodeIfPresent(Double.self, forKey: .carbsGrams) {
            carbsGrams = dbl
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .carbsGrams) {
            carbsGrams = Double(intVal)
        } else {
            carbsGrams = nil
        }

        if let dbl = try? container.decodeIfPresent(Double.self, forKey: .fatGrams) {
            fatGrams = dbl
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .fatGrams) {
            fatGrams = Double(intVal)
        } else {
            fatGrams = nil
        }
    }

    var proteinCalories: Double { (proteinGrams ?? 0) * 4 }
    var carbsCalories: Double { (carbsGrams ?? 0) * 4 }
    var fatCalories: Double { (fatGrams ?? 0) * 9 }
    var totalMacroCalories: Double { proteinCalories + carbsCalories + fatCalories }

    var proteinRatio: Double { totalMacroCalories > 0 ? proteinCalories / totalMacroCalories : 0 }
    var carbsRatio: Double { totalMacroCalories > 0 ? carbsCalories / totalMacroCalories : 0 }
    var fatRatio: Double { totalMacroCalories > 0 ? fatCalories / totalMacroCalories : 0 }
}

/// Detailed breakdown of nutritional strengths, moderation points, and cooking impacts.
struct HealthBreakdown: Codable, Hashable, Equatable {
    var positives: [String]
    var considerations: [String]
    var cookingImpact: String?
    var macros: MacroNutrients?

    enum CodingKeys: String, CodingKey {
        case positives
        case considerations
        case cookingImpact = "cooking_impact"
        case macros
    }

    init(
        positives: [String] = [],
        considerations: [String] = [],
        cookingImpact: String? = nil,
        macros: MacroNutrients? = nil
    ) {
        self.positives = positives
        self.considerations = considerations
        self.cookingImpact = cookingImpact
        self.macros = macros
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        positives = (try? container.decodeIfPresent([String].self, forKey: .positives)) ?? []
        considerations = (try? container.decodeIfPresent([String].self, forKey: .considerations)) ?? []
        cookingImpact = try? container.decodeIfPresent(String.self, forKey: .cookingImpact)
        macros = try? container.decodeIfPresent(MacroNutrients.self, forKey: .macros)
    }
}

/// A scientific nutritional quality evaluation of a recipe based on ingredients and cooking method.
struct HealthIndex: Codable, Hashable, Equatable {
    var score: Int
    var verdict: String
    var rationale: String
    var breakdown: HealthBreakdown?

    enum CodingKeys: String, CodingKey {
        case score = "health_score"
        case verdict = "health_verdict"
        case rationale = "health_rationale"
        case breakdown = "health_breakdown"
    }

    init(
        score: Int,
        verdict: String,
        rationale: String,
        breakdown: HealthBreakdown? = nil
    ) {
        self.score = max(1, min(100, score))
        self.verdict = verdict
        self.rationale = rationale
        self.breakdown = breakdown
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawScore = (try? container.decodeIfPresent(Int.self, forKey: .score)) ?? 50
        score = max(1, min(100, rawScore))
        verdict = (try? container.decodeIfPresent(String.self, forKey: .verdict)) ?? "Balanced"
        rationale = (try? container.decodeIfPresent(String.self, forKey: .rationale)) ?? ""
        breakdown = try? container.decodeIfPresent(HealthBreakdown.self, forKey: .breakdown)
    }

    var tier: HealthTier {
        if score >= 80 { return .nutritious }
        if score >= 60 { return .balanced }
        if score >= 40 { return .moderate }
        return .indulgent
    }

    var scoreColor: Color {
        tier.color
    }
}

/// Standard qualitative health classification tiers.
enum HealthTier: String, CaseIterable, Identifiable {
    case nutritious = "Nutritious"
    case balanced = "Balanced"
    case moderate = "Moderate"
    case indulgent = "Indulgent"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var rangeDescription: String {
        switch self {
        case .nutritious: return "80–100"
        case .balanced: return "60–79"
        case .moderate: return "40–59"
        case .indulgent: return "1–39"
        }
    }

    var explanation: String {
        switch self {
        case .nutritious:
            return "Rich in whole vegetables, legumes, whole grains, and lean protein with gentle cooking methods that preserve vitamins."
        case .balanced:
            return "Wholesome everyday meal providing a well-rounded balance of macronutrients with moderate fats and sodium."
        case .moderate:
            return "Enjoyable meal with moderately higher calorie density, refined carbohydrates, or sodium content."
        case .indulgent:
            return "Comfort food or treat, higher in saturated fats, sugars, or deep-fried preparation."
        }
    }

    var color: Color {
        switch self {
        case .nutritious:
            return DS.Color.Pine.pine600
        case .balanced:
            return Color("ds/reaction/good/text")
        case .moderate:
            return Color("ds/reaction/meh/text")
        case .indulgent:
            return Color("ds/reaction/bad/text")
        }
    }
}
