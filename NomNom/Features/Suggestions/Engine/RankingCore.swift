import Foundation

// MARK: - Tuning

/// Weights that turn dish history into a ranking. Each preset is a different
/// opinion about what "a good suggestion" means.
struct SuggestionWeights: Hashable {
    var like: Double
    var readiness: Double
    var exploration: Double
    var weekday: Double
    var dislikePenalty: Double

    static let balanced      = SuggestionWeights(like: 1.30, readiness: 0.90, exploration: 0.15, weekday: 0.20, dislikePenalty: 0.70)
    static let crowdPleasers = SuggestionWeights(like: 1.70, readiness: 0.45, exploration: 0.00, weekday: 0.15, dislikePenalty: 1.30)
    static let longTime      = SuggestionWeights(like: 0.60, readiness: 1.90, exploration: 0.25, weekday: 0.10, dislikePenalty: 0.55)
    static let adventurous   = SuggestionWeights(like: 0.35, readiness: 0.60, exploration: 1.70, weekday: 0.10, dislikePenalty: 0.25)
}

// MARK: - Inputs
//
// The ranking maths is deliberately free of SwiftData and SwiftUI: it works on
// plain values so it can be reasoned about (and tested) on its own.

struct ServingRecord<EaterID: Hashable> {
    let date: Date
    /// `eater == nil` means "the table as a whole" — used before the kids are set up.
    let reactions: [(eater: EaterID?, score: Double)]

    init(date: Date, reactions: [(eater: EaterID?, score: Double)]) {
        self.date = date
        self.reactions = reactions
    }
}

struct DishRecord<DishID: Hashable, EaterID: Hashable> {
    let id: DishID
    /// Any order; the ranker sorts.
    let servings: [ServingRecord<EaterID>]
}

// MARK: - Output

struct DishMetrics<EaterID: Hashable> {
    /// Recency-weighted mean verdict, 0...1. `nil` when nobody ever rated it.
    var likeScore: Double?
    /// 0...1 — how much evidence is behind `likeScore`.
    var confidence: Double
    /// 0...1 — how overdue the dish is, relative to its own usual rhythm.
    var readiness: Double
    /// 0...1 — bigger for dishes we know less about.
    var exploration: Double
    /// 0...1 — share of servings that landed on today's weekday.
    var weekdayAffinity: Double
    var weekdayHits: Int
    var timesServed: Int
    var lastServed: Date?
    var daysSinceServed: Int?
    /// Mean days between servings, `nil` with fewer than two servings.
    var typicalGapDays: Double?
    var perEater: [EaterID: (score: Double, count: Int)]

    /// 0 when nobody minds it, 1 when somebody's recent verdict was a flat no.
    ///
    /// Falls back to the overall score when verdicts were logged without naming an
    /// eater, so a dish nobody liked still gets penalised.
    var dislikeSeverity: Double {
        guard let worst = perEater.values.map(\.score).min() ?? likeScore else { return 0 }
        return min(1, max(0, (0.5 - worst) * 2))
    }
}

// MARK: - Ranker

struct Ranker {
    /// How fast an old verdict stops counting. Kids change their minds, so ~6 months.
    var reactionHalfLifeDays: Double = 180
    /// Rotation period assumed for a dish we've only cooked once.
    var defaultGapDays: Double = 14
    /// Verdict weight at which we call `likeScore` trustworthy.
    var confidenceSaturation: Double = 6
    /// Readiness given to a dish we've never cooked. Deliberately below 1: with no
    /// rotation history it isn't "overdue", it's just available. Novelty is the
    /// exploration term's job, and letting both max out double-counts it.
    var neverServedReadiness: Double = 0.7
    var now: Date = .now
    var calendar: Calendar = .current

    func metrics<D: Hashable, E: Hashable>(for record: DishRecord<D, E>) -> DishMetrics<E> {
        let servings = record.servings.sorted { $0.date < $1.date }
        let lastServed = servings.last?.date
        let daysSince = lastServed.map { max(0, Int((now.timeIntervalSince($0) / 86_400).rounded(.down))) }

        // --- liking, weighted towards recent verdicts ---
        var weightedSum = 0.0
        var weightTotal = 0.0
        var perEaterAccumulator: [E: (sum: Double, weight: Double, count: Int)] = [:]

        for serving in servings {
            let ageDays = max(0, now.timeIntervalSince(serving.date) / 86_400)
            let recencyWeight = pow(0.5, ageDays / reactionHalfLifeDays)
            for reaction in serving.reactions {
                weightedSum += reaction.score * recencyWeight
                weightTotal += recencyWeight
                guard let eater = reaction.eater else { continue }
                var bucket = perEaterAccumulator[eater] ?? (0, 0, 0)
                bucket.sum += reaction.score * recencyWeight
                bucket.weight += recencyWeight
                bucket.count += 1
                perEaterAccumulator[eater] = bucket
            }
        }

        let likeScore: Double? = weightTotal > 0 ? weightedSum / weightTotal : nil
        let confidence = min(1, weightTotal / confidenceSaturation)

        var perEater: [E: (score: Double, count: Int)] = [:]
        for (eater, bucket) in perEaterAccumulator where bucket.weight > 0 {
            perEater[eater] = (bucket.sum / bucket.weight, bucket.count)
        }

        // --- rotation ---
        let gaps = zip(servings, servings.dropFirst()).map { earlier, later in
            max(1, later.date.timeIntervalSince(earlier.date) / 86_400)
        }
        let typicalGap: Double? = gaps.isEmpty ? nil : gaps.reduce(0, +) / Double(gaps.count)
        // A dish we normally eat weekly feels overdue much sooner than one we eat
        // twice a year, so the time constant follows the dish's own rhythm.
        let tau = min(max(typicalGap ?? defaultGapDays, 4), 60)
        let readiness: Double = {
            guard let daysSince else { return neverServedReadiness }
            return 1 - exp(-Double(daysSince) / tau)
        }()

        // --- exploration (UCB-flavoured): reward what we know least about ---
        let exploration = 1 / (1 + weightTotal).squareRoot()

        // --- weekday affinity, so taco Friday surfaces on Fridays ---
        let todayWeekday = calendar.component(.weekday, from: now)
        let weekdayHits = servings.filter { calendar.component(.weekday, from: $0.date) == todayWeekday }.count
        let weekdayAffinity = servings.isEmpty ? 0 : Double(weekdayHits) / Double(servings.count)

        return DishMetrics(likeScore: likeScore,
                           confidence: confidence,
                           readiness: readiness,
                           exploration: exploration,
                           weekdayAffinity: weekdayAffinity,
                           weekdayHits: weekdayHits,
                           timesServed: servings.count,
                           lastServed: lastServed,
                           daysSinceServed: daysSince,
                           typicalGapDays: typicalGap,
                           perEater: perEater)
    }

    /// Combines the metrics into the number the list is sorted by.
    func score<E: Hashable>(_ metrics: DishMetrics<E>, weights: SuggestionWeights) -> Double {
        // An unrated dish gets a neutral 0.5 rather than a 0, so it isn't punished
        // for being unknown; the exploration term is what actually promotes it.
        let effectiveLike = metrics.likeScore ?? 0.5
        return weights.like * effectiveLike
            + weights.readiness * metrics.readiness
            + weights.exploration * metrics.exploration
            + weights.weekday * metrics.weekdayAffinity
            - weights.dislikePenalty * metrics.dislikeSeverity
    }
}
