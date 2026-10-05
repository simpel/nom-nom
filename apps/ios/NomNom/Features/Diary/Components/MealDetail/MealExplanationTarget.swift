import Foundation

/// Why one rater scored a meal the way they did: what RaterScoreSheet shows.
struct MealExplanationTarget: Identifiable {
    let id = UUID()
    let raterName: String
    /// Notable affinities; empty when there is nothing to explain.
    let affinities: [RaterTagAffinity]
    /// Their score for this meal, 0–1.
    var score: Double?
    /// Their usual score without this meal, 0–1.
    var usualScore: Double?
    /// How many ratings they have given in all.
    var ratingCount: Int = 0

    @MainActor
    init(rater: RaterRef, name: String, meal: Meal, store: FoodStore) {
        self.raterName = name
        self.affinities = store.raterExplanation(for: rater, meal: meal)
        self.score = store.rating(for: rater, on: meal.id)?.score
        self.usualScore = store.usualScore(for: rater, excluding: meal.id)
        self.ratingCount = store.ratings(for: rater).count
    }

    /// "Anna’s", or "Your" for the viewer (whose `raterName` is "You").
    var possessive: String { raterName == "You" ? "Your" : "\(raterName)\u{2019}s" }

    /// "8 above Anna’s usual of 84", with the emphasised run.
    var lead: (text: String?, emphasis: String?) {
        guard let score else { return (nil, nil) }
        guard let usualScore else { return ("\(possessive) first rating.", nil) }
        let usualPoints = Int((usualScore * 100).rounded())
        let delta = Int(((score - usualScore) * 100).rounded())
        let owner = "\(possessive.lowercasedIfYour) usual of \(usualPoints)"
        if delta == 0 { return ("Right on \(owner).", nil) }
        let emphasis = "\(abs(delta)) \(delta > 0 ? "above" : "below")"
        return ("\(emphasis) \(owner).", emphasis)
    }

    var provenance: String? {
        guard ratingCount > 0 else { return nil }
        let count = ratingCount == 1 ? "1 rating" : "\(ratingCount) ratings"
        return "Based on \(possessive.lowercasedIfYour) \(count)"
    }

    func reasons() -> [SheetReason] {
        affinities.map { affinity in
            SheetReason(id: affinity.id, title: Self.heading(for: affinity), text: affinity.sentence(name: raterName))
        }
    }

    private static func heading(for affinity: RaterTagAffinity) -> String {
        switch affinity.kind {
        case .dishKind(let name): return "Dish kind: \(name)"
        case .cookingMethod(let name): return "Cooking method: \(name.capitalized)"
        case .ingredient(let name): return "Ingredient: \(name.capitalized)"
        case .cuisine(let name): return "Cuisine: \(name.capitalized)"
        case .baseline: return "Overall baseline"
        }
    }
}

private extension String {
    /// "Your" mid-sentence reads "your".
    var lowercasedIfYour: String { self == "Your" ? "your" : self }
}
