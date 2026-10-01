import Foundation

struct PartyInsights: Identifiable, Hashable, Decodable {
    let id: UUID
    let partyID: UUID
    let summarySentence: String?
    let recommendations: [PartyInsightRecommendation]
    let memberMatches: [PartyMemberMatchInsight]
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case partyID = "party_id"
        case summarySentence = "summary_sentence"
        case recommendations
        case memberMatches = "member_matches"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        partyID = try container.decode(UUID.self, forKey: .partyID)
        summarySentence = try container.decodeIfPresent(String.self, forKey: .summarySentence)
        recommendations = try container.decodeIfPresent([PartyInsightRecommendation].self, forKey: .recommendations) ?? []
        memberMatches = try container.decodeIfPresent([PartyMemberMatchInsight].self, forKey: .memberMatches) ?? []
        updatedAt = try container.decodeTimestamp(.updatedAt)
    }

    init(
        id: UUID = UUID(),
        partyID: UUID,
        summarySentence: String? = nil,
        recommendations: [PartyInsightRecommendation] = [],
        memberMatches: [PartyMemberMatchInsight] = [],
        updatedAt: Date = .now
    ) {
        self.id = id
        self.partyID = partyID
        self.summarySentence = summarySentence
        self.recommendations = recommendations
        self.memberMatches = memberMatches
        self.updatedAt = updatedAt
    }
}

struct PartyMemberMatchInsight: Identifiable, Hashable, Decodable, Sendable {
    var id: String { memberID ?? memberName }
    let memberID: String?
    let memberName: String
    let explanation: String?

    enum CodingKeys: String, CodingKey {
        case memberID = "member_id"
        case memberName = "member_name"
        case explanation
    }
}

enum TasteTrendDirection: String, Hashable, Equatable, Sendable {
    case up
    case down
    case flat

    var systemImage: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }

    var label: String {
        switch self {
        case .up: return "Trending up"
        case .down: return "Trending down"
        case .flat: return "Steady"
        }
    }
}

/// Statistics and explanation for a single member's taste alignment with the dinner party.
struct MemberTasteMatch: Identifiable, Hashable, Equatable, Sendable {
    let ref: RaterRef
    let name: String
    let emoji: String
    let matchScore: Int // 0 to 100 percentage
    var mismatchScore: Int { max(0, 100 - matchScore) }
    let ratedMealsCount: Int
    let trend: TasteTrendDirection?
    let trendDelta: Int?
    let explanation: String?

    var id: RaterRef { ref }
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
