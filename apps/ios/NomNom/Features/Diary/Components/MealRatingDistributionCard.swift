import SwiftUI

/// How the table's verdicts split across reaction tiers: a SegmentedBar with a
/// legend ("2 · 50%") in a SectionCard, best tier first.
struct MealRatingDistributionCard: View {
    let ratings: [MealRating]

    private var segments: [SegmentedBarSegment] {
        let counts = Dictionary(grouping: ratings, by: \.reaction).mapValues(\.count)
        return Reaction.allCases.reversed().compactMap { reaction in
            guard let count = counts[reaction], count > 0 else { return nil }
            let percent = Int((Double(count) / Double(max(ratings.count, 1)) * 100).rounded())
            return SegmentedBarSegment(
                value: Double(count),
                color: reaction.fill,
                label: reaction.shortLabel,
                valueText: "\(count) \u{00B7} \(percent)%"
            )
        }
    }

    private var trailing: String {
        if ratings.isEmpty { return "Awaiting ratings" }
        return ratings.count == 1 ? "1 rating" : "\(ratings.count) ratings"
    }

    var body: some View {
        SectionCard("Who thought what", trailing: trailing) {
            if ratings.isEmpty {
                // README case "Nobody has rated": inside the SectionCard, so `plain`.
                EmptyState(
                    "Nobody has rated this",
                    message: "Ratings show up here as the party rates the meal.",
                    layout: .plain
                )
            } else {
                SegmentedBar(segments, label: "Rating distribution")
            }
        }
    }
}

#Preview {
    NomNomPreview { _ in
        VStack(spacing: DS.Spacing.block) {
            MealRatingDistributionCard(ratings: [
                MealRating(mealID: UUID(), reaction: .amazing),
                MealRating(mealID: UUID(), reaction: .amazing),
                MealRating(mealID: UUID(), reaction: .great),
                MealRating(mealID: UUID(), reaction: .good)
            ])
            MealRatingDistributionCard(ratings: [])
        }
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
    }
}
