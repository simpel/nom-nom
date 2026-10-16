import SwiftUI

/// Meal Detail's "Who rated": "3 of 5" in `primary-text`, then one Card of everyone who
/// can rate, alphabetical. State never splits the list (DS README, "One list, never split
/// by state"): rated rows show a score, unrated rows carry the Ask / Remind / Rate button.
/// Every row opens a rater sheet; the viewer's own unrated row opens the rating sheet.
struct MealDetailRatingsSection: View {
    let meal: Meal
    let onRate: (() -> Void)?

    @Environment(FoodStore.self) private var store
    @State private var target: MealRaterTarget?

    var body: some View {
        let raters = store.raters(forMeal: meal).sorted {
            displayName($0).localizedCaseInsensitiveCompare(displayName($1)) == .orderedAscending
        }
        let ratedCount = raters.filter { $0.rating != nil }.count

        DSSection("Who rated", trailing: "\(ratedCount) of \(raters.count)", trailingTone: .primary) {
            Card(layout: .list) {
                ForEach(raters) { rater in
                    MealRaterRow(meal: meal, rater: rater) { open(rater) }
                }
            }
        }
        .sheet(item: $target) { target in
            if target.hasRated {
                RaterScoreSheet(meal: meal, rater: target.ref)
            } else {
                RaterPendingSheet(meal: meal, rater: target.ref)
            }
        }
    }

    /// The name the row shows (the viewer too, marked by a "You" Badge), so the list reads alphabetically as drawn.
    private func displayName(_ rater: FoodStore.MealRater) -> String {
        store.firstName(for: rater.ref)
    }

    private func open(_ rater: FoodStore.MealRater) {
        if rater.isViewer && rater.rating == nil {
            onRate?()
        } else {
            target = MealRaterTarget(ref: rater.ref, hasRated: rater.rating != nil)
        }
    }
}
