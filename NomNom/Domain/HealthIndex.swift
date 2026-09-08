import SwiftUI

/// Detailed breakdown of nutritional strengths, moderation points, and cooking impacts.
struct HealthBreakdown: Codable, Hashable, Equatable {
    var positives: [String]
    var considerations: [String]
    var cookingImpact: String?

    enum CodingKeys: String, CodingKey {
        case positives
        case considerations
        case cookingImpact = "cooking_impact"
    }

    init(
        positives: [String] = [],
        considerations: [String] = [],
        cookingImpact: String? = nil
    ) {
        self.positives = positives
        self.considerations = considerations
        self.cookingImpact = cookingImpact
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
            return DS.Color.Pine.pine500
        case .moderate:
            return DS.Color.Stone.stone600
        case .indulgent:
            return DS.Color.Stone.stone500
        }
    }
}
