import SwiftUI

/// How the table's verdicts split across the taste scale: a SegmentedBar whose
/// breakdown is a RatingList (one row per tier, Can't eat → Amazing, zeros kept).
struct MealRatingDistributionCard: View {
    let ratings: [MealRating]

    private var counts: [Reaction: Int] {
        Dictionary(grouping: ratings, by: \.reaction).mapValues(\.count)
    }

    private var trailing: String {
        ratings.count == 1 ? "1 rating" : "\(ratings.count) ratings"
    }

    var body: some View {
        if ratings.isEmpty {
            SectionCard("Who thought what", trailing: "Awaiting ratings") {
                Text("No dinner party members have submitted a rating for this meal yet.")
                    .textStyle(.sansMd, tone: .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            SegmentedBar(
                .reactions(counts),
                legend: .rows,
                title: "Who thought what",
                trailing: trailing
            )
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
