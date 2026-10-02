import Foundation

// Modes and filters live in SuggestionMode.swift.

// MARK: - Output

struct EaterVerdict: Identifiable, Hashable {
    let ref: RaterRef
    let name: String
    /// Recency-weighted 0...1, `nil` when this person never rated the dish.
    let score: Double?
    let sampleCount: Int

    var id: RaterRef { ref }

    var reaction: Reaction? {
        score.map(Reaction.init(score:))
    }
}

struct Suggestion: Identifiable {
    let dish: Dish
    let score: Double
    let likeScore: Double?
    let confidence: Double
    let timesServed: Int
    let lastServed: Date?
    let daysSinceServed: Int?
    let readiness: Double
    let typicalGapDays: Double?
    let verdicts: [EaterVerdict]
    let reasons: [String]
    /// Most recent photo of this dish, for the row thumbnail. A storage path now,
    /// not bytes — the row loads it through `PhotoCache`.
    let photoPath: String?

    var id: UUID { dish.id }

    var name: String { dish.name }
}

// MARK: - Engine

/// Adapts the stored rows onto `Ranker`, applies the filters and writes the
/// human-readable "why" chips.
///
/// Takes plain values rather than the store, so the weights can still be tuned
/// against a hand-built fixture without a database anywhere in sight.
struct SuggestionEngine {
    var ranker = Ranker()

    struct Inputs {
        var dishes: [Dish]
        var mealsByDish: [UUID: [Meal]]
        var ratingsByMeal: [UUID: [MealRating]]
        /// Everyone whose opinion the UI shows a column for.
        var roster: [(ref: RaterRef, name: String)]
    }

    func rank(_ inputs: Inputs, filters: SuggestionFilters) -> [Suggestion] {
        let weights = filters.mode.weights
        let query = filters.searchText.normalizedForMatching

        var results: [Suggestion] = []

        for dish in inputs.dishes {
            let servings = inputs.mealsByDish[dish.id] ?? []
            let record = Self.record(for: dish, servings: servings, ratingsByMeal: inputs.ratingsByMeal)
            let metrics = ranker.metrics(for: record)

            // --- filters ---
            if !query.isEmpty,
               !dish.normalizedName.contains(query),
               !dish.normalizedName.matchTokens.contains(where: { $0.hasPrefix(query) }) {
                continue
            }
            if metrics.likeScore == nil, !filters.includeUntried { continue }
            if let days = metrics.daysSinceServed, days < filters.minDaysSinceServed { continue }
            // Catches both a named eater's flat no and an unnamed "nobody liked it".
            if filters.hideDisliked, metrics.dislikeSeverity > 0.5 { continue }
            if !filters.requiredRaters.isEmpty {
                let satisfied = filters.requiredRaters.allSatisfy { ref in
                    guard let entry = metrics.perEater[ref] else { return filters.includeUntried }
                    return entry.score >= 0.55
                }
                if !satisfied { continue }
            }

            let verdicts = inputs.roster.map { person -> EaterVerdict in
                let entry = metrics.perEater[person.ref]
                return EaterVerdict(ref: person.ref,
                                    name: person.name,
                                    score: entry?.score,
                                    sampleCount: entry?.count ?? 0)
            }

            let photoPath = servings
                .sorted { $0.eatenOn > $1.eatenOn }
                .first { $0.photoPath != nil }?
                .photoPath

            results.append(Suggestion(dish: dish,
                                      score: ranker.score(metrics, weights: weights),
                                      likeScore: metrics.likeScore,
                                      confidence: metrics.confidence,
                                      timesServed: metrics.timesServed,
                                      lastServed: metrics.lastServed,
                                      daysSinceServed: metrics.daysSinceServed,
                                      readiness: metrics.readiness,
                                      typicalGapDays: metrics.typicalGapDays,
                                      verdicts: verdicts,
                                      reasons: Self.reasons(metrics: metrics,
                                                            verdicts: verdicts,
                                                            now: ranker.now),
                                      photoPath: photoPath))
        }

        return results.sorted { lhs, rhs in
            if lhs.score == rhs.score { return lhs.name < rhs.name }
            return lhs.score > rhs.score
        }
    }

    // MARK: Rows → value bridge

    static func record(for dish: Dish,
                       servings: [Meal],
                       ratingsByMeal: [UUID: [MealRating]]) -> DishRecord<UUID, RaterRef> {
        DishRecord(id: dish.id,
                   servings: servings.map { meal in
                       ServingRecord(date: meal.eatenOn,
                                     reactions: (ratingsByMeal[meal.id] ?? []).map {
                                         (eater: Optional($0.source), score: $0.reaction.score)
                                     })
                   })
    }

    // MARK: Explanations

    /// Short chips explaining why something is near the top. Without them the
    /// ranking is a black box and you stop trusting it.
    static func reasons(metrics: DishMetrics<RaterRef>,
                        verdicts: [EaterVerdict],
                        now: Date) -> [String] {
        var reasons: [String] = []
        let rated = verdicts.filter { $0.score != nil }

        if let likeScore = metrics.likeScore {
            if likeScore >= 0.85, rated.count >= 2 {
                reasons.append("Everyone's happy")
            } else if likeScore >= 0.8 {
                reasons.append("Big hit")
            } else if likeScore >= 0.6 {
                reasons.append("Generally liked")
            } else if likeScore < 0.35 {
                reasons.append("Tough crowd")
            }

            let scores = rated.compactMap(\.score)
            if scores.count >= 2, let hi = scores.max(), let lo = scores.min(), hi - lo >= 0.5,
               let fan = rated.first(where: { $0.score == hi }),
               let foe = rated.first(where: { $0.score == lo }) {
                reasons.append("\(fan.name) yes, \(foe.name) no")
            }
        }

        // The row subtitle already states *when* we last cooked it, so a chip only
        // earns its place by adding a judgement on top of that number.
        if let days = metrics.daysSinceServed {
            if days >= 60 {
                reasons.append("Long overdue")
            } else if metrics.readiness > 0.85, days >= 7 {
                reasons.append("Overdue — \(days) days")
            }
        }

        if metrics.timesServed == 1 {
            reasons.append("Only tried once")
        } else if metrics.confidence < 0.4, metrics.timesServed > 0 {
            reasons.append("Still figuring it out")
        }

        if let gap = metrics.typicalGapDays, metrics.timesServed >= 3, gap <= 21 {
            reasons.append("Usually every \(Int(gap.rounded())) days")
        }

        if metrics.weekdayHits >= 2, metrics.weekdayAffinity >= 0.5 {
            reasons.append("A \(weekdayName(for: now)) thing")
        }

        return reasons
    }

    private static func weekdayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE")
        return formatter.string(from: date)
    }
}
