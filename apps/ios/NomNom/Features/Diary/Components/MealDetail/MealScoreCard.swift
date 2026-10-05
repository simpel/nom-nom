import SwiftUI

/// Meal Detail's one score card: the hero ScoreValue, what changed since last time, and
/// how the ratings split as a SegmentedBar `sm` with its inline key, then "3 of 5 rated
/// so far". The split replaces ScoreCard's progress Bar: the numeral already says
/// "90", and a second bar under it read as noise (DS-GAPS.md B, "Meal score card").
/// Built from ScoreCard's parts (Card `md`, ScoreValue `lg`, the delta line) so it
/// reads as a ScoreCard. Pressable: opens the score breakdown.
///
/// Unrated (`score` nil, DS-GAPS.md B, "Meal score card, unrated"): "No score yet"
/// `serif-sm` over "0 of 4 have rated", and a "Remind" AppButton `sm` on the right when
/// `onRemind` is set (`secondary soft`, like every Remind). Not pressable: there is no
/// breakdown yet.
struct MealScoreCard: View {
    let score: Double?
    let ratings: [MealRating]
    var raterCount: Int = 0
    var onRemind: (() -> Void)?
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
        if score == nil {
            unrated
        } else {
            rated
        }
    }

    private var unrated: some View {
        Card(size: .md) {
            HStack(alignment: .center, spacing: DS.Spacing.s4) {
                VStack(alignment: .leading, spacing: DS.Spacing.s0_5) {
                    Text("No score yet")
                        .textStyle(.serifSm)
                    Text("\(ratings.count) of \(raterCount) have rated")
                        .textStyle(.sansSm, tone: .secondary, numeric: true)
                }
                .accessibilityElement(children: .combine)
                Spacer(minLength: 0)
                if let onRemind {
                    AppButton("Remind", variant: .secondary, appearance: .soft, size: .sm, action: onRemind)
                }
            }
        }
    }

    private var rated: some View {
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
