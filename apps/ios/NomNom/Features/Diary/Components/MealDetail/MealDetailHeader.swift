import SwiftUI

/// Meal Detail's DetailHeader: "date · party" meta, the table's verdict as a
/// sentence, the dish and its cook as the summary, effort / kind / method /
/// rotation fact Badges, and "Rate this meal" (or "You rated 90").
struct MealDetailHeader: View {
    let meal: Meal
    let onRate: () -> Void

    @Environment(FoodStore.self) private var store

    var body: some View {
        DetailHeader(
            title: Self.verdictSentence(for: store.averageReaction(forMeal: meal.id)),
            meta: meta,
            summary: summary,
            facts: facts,
            actions: [action]
        )
    }

    /// The table's verdict as a sentence.
    static func verdictSentence(for reaction: Reaction?) -> String {
        switch reaction {
        case .amazing, .great: return "The table loved it."
        case .good: return "The table liked it."
        case .meh: return "The table was lukewarm."
        case .bad: return "The table wasn\u{2019}t keen."
        case .inedible: return "The table couldn\u{2019}t eat it."
        case nil: return "Waiting on the table\u{2019}s verdict."
        }
    }

    private var meta: String {
        let date = meal.eatenOn.formatted(.dateTime.day().month(.abbreviated).year())
        let party = store.partyDisplayName(forMeal: meal)
        return party == "You" ? date : "\(date) \u{00B7} \(party)"
    }

    private var summary: String {
        let dish = store.dishName(forMeal: meal)
        let cook = meal.createdBy == store.userID ? "you" : store.firstName(for: .account(meal.createdBy))
        return "\(dish), cooked by \(cook)."
    }

    private var facts: [Badge] {
        let recipe = store.dish(meal.dishID)
        var facts: [Badge] = []
        if let effort = meal.effort ?? recipe?.effort {
            facts.append(Badge(effort.label, variant: .secondary, size: .sm))
        }
        if let recipe, let kind = store.dishKind(for: recipe) {
            facts.append(Badge(kind.name, variant: .secondary, size: .sm))
        }
        if let recipe, let method = store.cookingMethod(for: recipe) {
            facts.append(Badge(method.name, variant: .secondary, size: .sm))
        }
        if let rotation = store.averageRotation(forMeal: meal.id) {
            facts.append(.rotation(rotation))
        }
        return facts
    }

    private var action: DetailHeaderAction {
        if let mine = store.myRating(forMeal: meal.id) {
            let points = Int((mine.score * 100).rounded())
            return DetailHeaderAction(title: "You rated \(points)", appearance: .soft, action: onRate)
        }
        return DetailHeaderAction(title: "Rate this meal", action: onRate)
    }
}
