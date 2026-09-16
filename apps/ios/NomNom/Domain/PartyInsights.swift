import Foundation

struct PartyInsights: Identifiable, Hashable, Decodable {
    let id: UUID
    let partyID: UUID
    let summarySentence: String?
    let foodProfile: String?
    let recommendations: [PartyInsightRecommendation]
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case partyID = "party_id"
        case summarySentence = "summary_sentence"
        case foodProfile = "food_profile"
        case recommendations
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        partyID = try container.decode(UUID.self, forKey: .partyID)
        summarySentence = try container.decodeIfPresent(String.self, forKey: .summarySentence)
        foodProfile = try container.decodeIfPresent(String.self, forKey: .foodProfile)
        recommendations = try container.decodeIfPresent([PartyInsightRecommendation].self, forKey: .recommendations) ?? []
        updatedAt = try container.decodeTimestamp(.updatedAt)
    }

    init(
        id: UUID = UUID(),
        partyID: UUID,
        summarySentence: String? = nil,
        foodProfile: String? = nil,
        recommendations: [PartyInsightRecommendation] = [],
        updatedAt: Date = .now
    ) {
        self.id = id
        self.partyID = partyID
        self.summarySentence = summarySentence
        self.foodProfile = foodProfile
        self.recommendations = recommendations
        self.updatedAt = updatedAt
    }
}

struct PartyInsightRecommendation: Identifiable, Hashable, Decodable {
    var id: String { title } // use title as id
    let title: String
    let description: String
    let cuisine: String?
    let dishID: UUID?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case cuisine
        case dishID = "dish_id"
    }
}

/// Locally computed health aggregate metrics for a party based on their active meals.
struct PartyHealthInsights: Hashable, Equatable {
    let averageHealthScore: Int?
    let healthTierDistribution: [HealthTier: Double]
    let topStrengths: [String]
    let topConsiderations: [String]
    let averageMacros: MacroNutrients?
    let healthScoreTrend: [(date: Date, averageHealthScore: Double)]
    
    static func == (lhs: PartyHealthInsights, rhs: PartyHealthInsights) -> Bool {
        lhs.averageHealthScore == rhs.averageHealthScore &&
        lhs.healthTierDistribution == rhs.healthTierDistribution &&
        lhs.topStrengths == rhs.topStrengths &&
        lhs.topConsiderations == rhs.topConsiderations &&
        lhs.averageMacros == rhs.averageMacros &&
        lhs.healthScoreTrend.map { $0.date } == rhs.healthScoreTrend.map { $0.date } &&
        lhs.healthScoreTrend.map { $0.averageHealthScore } == rhs.healthScoreTrend.map { $0.averageHealthScore }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(averageHealthScore)
        hasher.combine(topStrengths)
        hasher.combine(topConsiderations)
        hasher.combine(averageMacros)
        for (tier, pct) in healthTierDistribution {
            hasher.combine(tier)
            hasher.combine(pct)
        }
        for point in healthScoreTrend {
            hasher.combine(point.date)
            hasher.combine(point.averageHealthScore)
        }
    }
}

/// One rater's (member or household eater) score trend within a party, for
/// per-member breakdowns of the party's overall rating trend.
struct MemberTrendSeries: Identifiable, Hashable {
    let ref: RaterRef
    let name: String
    let emoji: String
    let points: [(date: Date, score: Double)]

    var id: RaterRef { ref }

    static func == (lhs: MemberTrendSeries, rhs: MemberTrendSeries) -> Bool {
        lhs.ref == rhs.ref &&
        lhs.name == rhs.name &&
        lhs.emoji == rhs.emoji &&
        lhs.points.map(\.date) == rhs.points.map(\.date) &&
        lhs.points.map(\.score) == rhs.points.map(\.score)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ref)
        hasher.combine(name)
        hasher.combine(emoji)
        for point in points {
            hasher.combine(point.date)
            hasher.combine(point.score)
        }
    }
}
