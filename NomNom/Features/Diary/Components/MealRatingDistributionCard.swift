import SwiftUI

/// Infographic card presenting the dinner party's consensus distribution across reaction tiers.
/// Displays a segmented proportional bar and individual reaction counts.
struct MealRatingDistributionCard: View {
    let ratings: [MealRating]

    private var groupedCounts: [(reaction: Reaction, count: Int, percent: Int)] {
        guard !ratings.isEmpty else { return [] }
        let counts = Dictionary(grouping: ratings, by: \.reaction)
            .mapValues(\.count)

        // Sort descending by reaction score (Amazing -> Inedible)
        return Reaction.allCases
            .reversed()
            .compactMap { reaction in
                guard let count = counts[reaction], count > 0 else { return nil }
                let percent = Int((Double(count) / Double(ratings.count) * 100).rounded())
                return (reaction, count, percent)
            }
    }

    var body: some View {
        SectionCard(
            "Consensus Distribution",
            caption: ratings.isEmpty ? "Awaiting ratings" : "\(ratings.count) \(ratings.count == 1 ? "rating" : "ratings")"
        ) {
            if ratings.isEmpty {
                Text("No dinner party members have submitted a rating for this meal yet.")
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    // Segmented proportion bar
                    segmentedDistributionBar

                    // Reaction breakdown rows
                    VStack(spacing: 8) {
                        ForEach(groupedCounts, id: \.reaction) { item in
                            breakdownRow(reaction: item.reaction, count: item.count, percent: item.percent)
                        }
                    }
                }
            }
        }
    }

    private var segmentedDistributionBar: some View {
        GeometryReader { proxy in
            HStack(spacing: 2) {
                ForEach(groupedCounts, id: \.reaction) { item in
                    let fraction = CGFloat(item.count) / CGFloat(max(ratings.count, 1))
                    let width = max(4, proxy.size.width * fraction - 2)

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(item.reaction.text)
                        .frame(width: width, height: 10)
                }
            }
        }
        .frame(height: 10)
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    private func breakdownRow(reaction: Reaction, count: Int, percent: Int) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(reaction.text)
                .frame(width: 8, height: 8)

            Text(reaction.shortLabel)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DS.Color.textPrimary)

            Spacer()

            Text("\(count) (\(percent)%)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(DS.Color.textSecondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NomNomPreview { _ in
        VStack(spacing: 20) {
            MealRatingDistributionCard(ratings: [
                MealRating(mealID: UUID(), reaction: .amazing),
                MealRating(mealID: UUID(), reaction: .amazing),
                MealRating(mealID: UUID(), reaction: .great),
                MealRating(mealID: UUID(), reaction: .good)
            ])
            MealRatingDistributionCard(ratings: [])
        }
        .padding()
    }
}
