import SwiftUI

/// Meal Detail's one score card: the hero ScoreValue, what changed since last time, and
/// how the ratings split as a SegmentedBar `sm` with its inline key, then "3 of 5 rated
/// so far". The split replaces ScoreCard's progress Bar: the numeral already says
/// "90", and a second bar under it read as noise (DS-GAPS.md B, "Meal score card").
/// Built from ScoreCard's parts (Card `md`, ScoreValue `lg`, the delta line) so it
/// reads as a ScoreCard. Pressable: opens the score breakdown.
struct MealScoreCard: View {
    let score: Double?
    let ratings: [MealRating]
    var delta: Int?
    var deltaText: String?
    var deltaReference: String?
    var caption: String?
    let action: () -> Void

    /// Eaters grouped by the tier their score reads as (not the verdict they tapped), so
    /// the split adds up to the numeral above it. Scale order (README: "Never sort by
    /// size"); only tiers someone landed in.
    private var segments: [SegmentedBarSegment] {
        let counts = Dictionary(grouping: ratings, by: \.tier).mapValues(\.count)
        return Reaction.allCases.sorted()
            .filter { (counts[$0] ?? 0) > 0 }
            .map { SegmentedBarSegment(reaction: $0, value: Double(counts[$0] ?? 0)) }
    }

    var body: some View {
        Card(size: .md, spacing: DS.Spacing.s3_5, action: action) {
            ScoreValue(score: score, size: .lg)

            if let delta {
                ScoreCardDeltaLine(delta: delta, text: deltaText, reference: deltaReference)
            }

            if !ratings.isEmpty {
                SegmentedBar(segments, legend: .inline, size: .sm,
                             label: "Ratings split across the taste scale")
            }

            if let caption {
                Text(caption)
                    .textStyle(.sansSm, tone: .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
