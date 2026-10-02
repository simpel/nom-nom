import SwiftUI

/// Meal Detail's "Who rated" ("Nom Nom iOS" canvas): "3 of 5" in `primary-text`, the
/// rated / total Bar `xs`, a Card of everyone who has rated (the viewer last), then
/// "Not yet" over a Card of everyone who hasn't. Every row opens a rater sheet; the
/// viewer's own unrated row opens the rating sheet.
struct MealDetailRatingsSection: View {
    let meal: Meal
    let onRate: () -> Void

    @Environment(FoodStore.self) private var store
    @State private var target: MealRaterTarget?

    var body: some View {
        let raters = store.raters(forMeal: meal)
        let rated = raters.filter { $0.rating != nil && !$0.isViewer } + raters.filter { $0.rating != nil && $0.isViewer }
        let pending = raters.filter { $0.rating == nil }

        DSSection("Who rated", trailing: "\(rated.count) of \(raters.count)", trailingTone: .primary) {
            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                RatingListMeter(rated: rated.count, total: raters.count)
                    .padding(.horizontal, DS.Spacing.sectionInset)
                if !rated.isEmpty {
                    Card(layout: .list) {
                        ForEach(rated) { rater in
                            MealRaterRow(meal: meal, rater: rater) { open(rater) }
                        }
                    }
                }
                if !pending.isEmpty {
                    SectionHeader(title: "Not yet")
                        .padding(.horizontal, DS.Spacing.sectionInset)
                        .padding(.top, DS.Spacing.s2)
                    Card(layout: .list) {
                        ForEach(pending) { rater in
                            MealRaterRow(meal: meal, rater: rater) { open(rater) }
                        }
                    }
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

    private func open(_ rater: FoodStore.MealRater) {
        if rater.isViewer && rater.rating == nil {
            onRate()
        } else {
            target = MealRaterTarget(ref: rater.ref, hasRated: rater.rating != nil)
        }
    }
}
