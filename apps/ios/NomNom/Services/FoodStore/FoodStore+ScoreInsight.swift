import Foundation

/// The one-sentence teaser on the meal score sheet's Pro card: the single most useful
/// thing the full breakdown would tell you. On device, from `tableExplanation` and the
/// recipe's history with this group.
extension FoodStore {

    func scoreInsight(forMeal meal: Meal) -> String {
        let reasons = tableExplanation(forMeal: meal)
        if let down = reasons.first(where: \.isNegative) {
            return sentence(for: down, meal: meal)
        }
        if let history = historySentence(forMeal: meal) {
            return history
        }
        if let up = reasons.first {
            return sentence(for: up, meal: meal)
        }
        return "The first time this group has had it. See what to change next time."
    }

    private func sentence(for reason: TableReason, meal: Meal) -> String {
        switch reason.source {
        case .tag:
            let raters = ratings(forMeal: meal.id).count
            let count = reason.count ?? 1
            let who = raters > 1 ? "\(count) of \(raters)" : "The one rating"
            return "\(who) said \(reason.title.lowercased())."
        case .pattern:
            guard let delta = reason.delta else { return "\(reason.detail)." }
            return "\(reason.detail), by \(abs(delta)) points."
        }
    }

    /// Where this serving sits among every time the group has had the recipe.
    private func historySentence(forMeal meal: Meal) -> String? {
        guard let current = averageScore(forMeal: meal.id) else { return nil }
        let past = partyHistory(for: meal).compactMap { past in
            averageScore(forMeal: past.id).map { (meal: past, score: $0) }
        }
        guard let first = past.last else { return nil }
        let times = past.count + 1
        let now = Int((current * 100).rounded())
        let then = Int((first.score * 100).rounded())
        let scores = past.map(\.score)
        if scores.allSatisfy({ $0 > current }) {
            return "The lowest of the \(times) times you\u{2019}ve had it, down from \(then) the first time."
        }
        if scores.allSatisfy({ $0 < current }) {
            return "The best of the \(times) times you\u{2019}ve had it, up from \(then) the first time."
        }
        return "\(now) now, against \(then) the first time, across \(times) meals."
    }
}
