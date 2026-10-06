import SwiftUI

/// What a MealRow's meta line says.
enum MealRowMeta {
    /// The parties it was served to (and, unless minimal, the verdict and effort).
    case parties
    /// The Meals list ("Nom Nom iOS" canvas): "{party} · 3 of 5 rated", or
    /// "{party} · Waiting on 2" in `warning-text` once the viewer has rated.
    case ratingProgress
    /// The date it was eaten ("Fri 25 Sep").
    case date
}

/// One meal in a list: a ListRow with the meal's PhotoCard thumbnail, the dish name,
/// a meta line and its score. Place it in a `Card(layout: .list)`.
///
/// With `.ratingProgress` the trailing slot is the meal's ScoreValue, or, while nobody
/// has rated and `onRemind` is set, a "Remind" AppButton that splits the row.
struct MealRow: View {
    let meal: Meal
    var raterRef: RaterRef? = nil
    var metaStyle: MealRowMeta = .parties
    /// Parties only in the meta line and no chevron.
    var isMinimal: Bool = false
    /// Makes the row pressable (opens the meal). Needed instead of a wrapping
    /// NavigationLink when the row carries a Remind button.
    var action: (() -> Void)? = nil
    /// Opens RemindRatersSheet.
    var onRemind: (() -> Void)? = nil

    @Environment(FoodStore.self) private var store

    /// The meal's verdict word, read from its score so word and numeral agree. A row
    /// about one eater shows their number only: no word.
    private var ratingSummaryText: String? {
        guard raterRef == nil else { return nil }
        return store.averageReaction(forMeal: meal.id)?.shortLabel
    }

    private var partyNames: String {
        store.parties(forMeal: meal.id).map(\.name).joined(separator: ", ")
    }

    private var score: Double? {
        if let raterRef, let rating = store.rating(for: raterRef, on: meal.id) {
            return rating.score
        }
        return store.averageScore(forMeal: meal.id)
    }

    private var raters: [FoodStore.MealRater] { store.raters(forMeal: meal) }
    private var viewerHasRated: Bool { raters.contains { $0.isViewer && $0.rating != nil } }

    private var meta: String {
        switch metaStyle {
        case .date:
            return meal.eatenOn.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        case .ratingProgress:
            return partyNames
        case .parties:
            if isMinimal { return partyNames }
            let effort = (meal.effort ?? store.dish(meal.dishID)?.effort)?.label
            return [partyNames, ratingSummaryText, effort]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " \u{00B7} ")
        }
    }

    /// "Waiting on N" once the viewer has rated and others haven't.
    private var waitingOn: ListRowMetaAccent? {
        guard metaStyle == .ratingProgress, viewerHasRated else { return nil }
        let pending = raters.filter { $0.rating == nil }.count
        return pending > 0 ? ListRowMetaAccent(text: "Waiting on \(pending)") : nil
    }

    /// A `primary soft sm` "Remind" while nobody has rated and someone can be nudged.
    private var showsRemind: Bool {
        guard onRemind != nil, metaStyle == .ratingProgress else { return false }
        return raters.allSatisfy { $0.rating == nil } && !store.remindableRaters(forMeal: meal).isEmpty
    }

    private var trailing: ListRowTrailing? {
        if showsRemind, let onRemind {
            return .button(AppButton("Remind", appearance: .soft, size: .sm, action: onRemind))
        }
        return .score(score)
    }

    var body: some View {
        // ListRow has one meta line (README: title + meta), so the cook's notes are
        // left to the meal screen.
        ListRow(
            store.dishName(forMeal: meal),
            meta: meta,
            metaAccent: waitingOn,
            leading: .photo(.meal(meal)),
            trailing: trailing,
            chevron: !isMinimal,
            action: action
        )
    }
}

#Preview("Rating progress") {
    NomNomPreview { store in
        Card(layout: .list) {
            ForEach(store.meals.prefix(4)) { meal in
                MealRow(meal: meal, metaStyle: .ratingProgress, isMinimal: true)
            }
        }
        .padding(DS.Spacing.gutter)
    }
}

#Preview("Full") {
    NomNomPreview { store in
        Card(layout: .list) {
            ForEach(store.meals.prefix(3)) { meal in
                MealRow(meal: meal)
            }
        }
        .padding(DS.Spacing.gutter)
    }
}
