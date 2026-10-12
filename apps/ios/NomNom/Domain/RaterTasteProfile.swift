import Foundation

/// A personal taste fingerprint: how one rater's verdicts skew, what they cook/eat most,
/// and their preferred recipe kinds.
struct RaterTasteProfile: Hashable {
    let averageScoreGiven: Double
    let ratingDistribution: [Reaction: Int]
    let topCuisines: [(cuisine: String, count: Int)]
    let topRecipeKinds: [(kindName: String, count: Int, averageScore: Double)]
    let totalRatingsGiven: Int

    init(
        averageScoreGiven: Double,
        ratingDistribution: [Reaction: Int],
        topCuisines: [(cuisine: String, count: Int)],
        topRecipeKinds: [(kindName: String, count: Int, averageScore: Double)] = [],
        totalRatingsGiven: Int
    ) {
        self.averageScoreGiven = averageScoreGiven
        self.ratingDistribution = ratingDistribution
        self.topCuisines = topCuisines
        self.topRecipeKinds = topRecipeKinds
        self.totalRatingsGiven = totalRatingsGiven
    }

    static func == (lhs: RaterTasteProfile, rhs: RaterTasteProfile) -> Bool {
        lhs.averageScoreGiven == rhs.averageScoreGiven &&
        lhs.ratingDistribution == rhs.ratingDistribution &&
        lhs.totalRatingsGiven == rhs.totalRatingsGiven &&
        lhs.topCuisines.map(\.cuisine) == rhs.topCuisines.map(\.cuisine) &&
        lhs.topCuisines.map(\.count) == rhs.topCuisines.map(\.count) &&
        lhs.topRecipeKinds.map(\.kindName) == rhs.topRecipeKinds.map(\.kindName) &&
        lhs.topRecipeKinds.map(\.count) == rhs.topRecipeKinds.map(\.count) &&
        lhs.topRecipeKinds.map(\.averageScore) == rhs.topRecipeKinds.map(\.averageScore)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(averageScoreGiven)
        hasher.combine(ratingDistribution)
        hasher.combine(totalRatingsGiven)
        for entry in topCuisines {
            hasher.combine(entry.cuisine)
            hasher.combine(entry.count)
        }
        for entry in topRecipeKinds {
            hasher.combine(entry.kindName)
            hasher.combine(entry.count)
            hasher.combine(entry.averageScore)
        }
    }
}
