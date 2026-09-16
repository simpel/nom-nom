import Foundation

/// A personal taste fingerprint: how one rater's verdicts skew, and what they cook/eat most.
struct RaterTasteProfile: Hashable {
    let averageScoreGiven: Double
    let ratingDistribution: [Reaction: Int]
    let topCuisines: [(cuisine: String, count: Int)]
    let totalRatingsGiven: Int

    static func == (lhs: RaterTasteProfile, rhs: RaterTasteProfile) -> Bool {
        lhs.averageScoreGiven == rhs.averageScoreGiven &&
        lhs.ratingDistribution == rhs.ratingDistribution &&
        lhs.totalRatingsGiven == rhs.totalRatingsGiven &&
        lhs.topCuisines.map(\.cuisine) == rhs.topCuisines.map(\.cuisine) &&
        lhs.topCuisines.map(\.count) == rhs.topCuisines.map(\.count)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(averageScoreGiven)
        hasher.combine(ratingDistribution)
        hasher.combine(totalRatingsGiven)
        for entry in topCuisines {
            hasher.combine(entry.cuisine)
            hasher.combine(entry.count)
        }
    }
}
