import SwiftUI

/// "How the ratings split" under Meal Detail's ScoreCard ("Nom Nom iOS" canvas): a
/// Card `sm` holding a SegmentedBar `sm` with an inline key, in scale order (README:
/// "Never sort by size"). Meh and up always show; Bad and Can't eat only when someone
/// chose them. Hidden until anyone has rated.
struct MealRatingSplitCard: View {
    let ratings: [MealRating]

    private var segments: [SegmentedBarSegment] {
        let counts = Dictionary(grouping: ratings, by: \.reaction).mapValues(\.count)
        return Reaction.allCases.sorted()
            .filter { $0 >= .meh || (counts[$0] ?? 0) > 0 }
            .map { SegmentedBarSegment(reaction: $0, value: Double(counts[$0] ?? 0)) }
    }

    var body: some View {
        if !ratings.isEmpty {
            Card(size: .sm) {
                SegmentedBar(
                    segments,
                    legend: .inline,
                    size: .sm,
                    label: "Ratings split across the taste scale",
                    title: "How the ratings split"
                )
            }
        }
    }
}
