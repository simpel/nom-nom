import Foundation

/// How often and how recently a dish has been cooked. Passed in rather than read
/// off the model, because a `Dish` row knows nothing about its meals — the join
/// lives in the store.
struct DishHistory {
    var timesServed: Int
    var lastServed: Date?

    static let none = DishHistory(timesServed: 0, lastServed: nil)
}

/// Everything that keeps dish names from drifting apart.
///
/// Find-or-create moved to `FoodStore`, since it is now a write that
/// has to go through Postgres and lean on `unique (owner_id, normalized_name)` to
/// settle a race. What's left here is pure matching, with no I/O in it.
enum DishRepository {

    // MARK: - Autofill

    struct NameSuggestion: Identifiable, Hashable {
        let dishID: UUID
        let name: String
        let timesServed: Int
        let lastServed: Date?
        /// Higher is a better match.
        let rank: Double

        var id: UUID { dishID }
    }

    /// Ranked autofill candidates for what the user has typed so far.
    ///
    /// Ranking, best first:
    ///   1. the whole name starts with the query
    ///   2. some word inside the name starts with the query
    ///   3. the name contains the query somewhere
    ///   4. the query is a near-typo of the name
    /// Ties are broken by how often we've cooked it and how recently.
    static func suggestions(for query: String,
                            in dishes: [Dish],
                            history: [UUID: DishHistory],
                            favoriteIDs: Set<UUID> = [],
                            limit: Int = 6) -> [NameSuggestion] {
        let q = query.normalizedForMatching
        guard !q.isEmpty else {
            // Nothing typed yet: offer favourites first, then dishes we cook the most, most recent first.
            return dishes
                .sorted { lhs, rhs in
                    let lFav = favoriteIDs.contains(lhs.id)
                    let rFav = favoriteIDs.contains(rhs.id)
                    if lFav != rFav { return lFav && !rFav }
                    let l = history[lhs.id]?.lastServed ?? lhs.createdAt
                    let r = history[rhs.id]?.lastServed ?? rhs.createdAt
                    return l > r
                }
                .prefix(limit)
                .map { suggestion(for: $0, history: history[$0.id] ?? .none, rank: 0) }
        }

        var scored: [NameSuggestion] = []
        for dish in dishes {
            let name = dish.normalizedName
            var base: Double

            let normalizedCuisine = dish.cuisine?.normalizedForMatching ?? ""
            let matchesTag = dish.tags.contains { $0.normalizedForMatching.contains(q) }
            let matchesIngredient = dish.ingredients.contains { $0.ingredient.normalizedForMatching.contains(q) }

            if name == q {
                base = 100
            } else if name.hasPrefix(q) {
                base = 80
            } else if dish.normalizedName.matchTokens.contains(where: { $0.hasPrefix(q) }) {
                base = 60
            } else if !normalizedCuisine.isEmpty && (normalizedCuisine == q || normalizedCuisine.hasPrefix(q)) {
                base = 55
            } else if name.contains(q) {
                base = 40
            } else if matchesTag || matchesIngredient || (!normalizedCuisine.isEmpty && normalizedCuisine.contains(q)) {
                base = 35
            } else if Fuzzy.isProbableTypo(name, q) {
                base = 25
            } else if q.count >= 4, Fuzzy.similarity(name, q) > 0.7 {
                base = 15
            } else {
                continue
            }

            let entry = history[dish.id] ?? .none

            // Prefer names that aren't much longer than what was typed, so "pasta"
            // ranks "Pasta" above "Pasta bolognese with extra cheese".
            let lengthPenalty = Double(max(0, name.count - q.count)) * 0.15
            // Familiar + recent wins ties.
            let familiarity = min(Double(entry.timesServed), 20) * 0.4
            let recency: Double = {
                guard let last = entry.lastServed else { return 0 }
                let days = Date.now.timeIntervalSince(last) / 86_400
                return max(0, 6 - days / 30)
            }()

            let isFavorite = favoriteIDs.contains(dish.id)
            let favoriteBonus = isFavorite ? 50.0 : 0.0

            scored.append(suggestion(for: dish,
                                     history: entry,
                                     rank: base - lengthPenalty + familiarity + recency + favoriteBonus))
        }

        return scored.sorted { $0.rank > $1.rank }.prefix(limit).map { $0 }
    }

    private static func suggestion(for dish: Dish, history: DishHistory, rank: Double) -> NameSuggestion {
        NameSuggestion(dishID: dish.id,
                       name: dish.name,
                       timesServed: history.timesServed,
                       lastServed: history.lastServed,
                       rank: rank)
    }

    // MARK: - Lookup

    static func exactMatch(for name: String, in dishes: [Dish]) -> Dish? {
        let key = name.normalizedForMatching
        guard !key.isEmpty else { return nil }
        return dishes.first { $0.normalizedName == key }
    }

    /// A dish whose name is one or two typos away from what was typed. Drives the
    /// "did you mean …?" banner in the editor.
    static func nearMatch(for name: String, in dishes: [Dish]) -> Dish? {
        let key = name.normalizedForMatching
        guard key.count >= 5 else { return nil }
        guard exactMatch(for: name, in: dishes) == nil else { return nil }
        return dishes
            .filter { Fuzzy.isProbableTypo($0.normalizedName, key) }
            .max { Fuzzy.similarity($0.normalizedName, key) < Fuzzy.similarity($1.normalizedName, key) }
    }
}
