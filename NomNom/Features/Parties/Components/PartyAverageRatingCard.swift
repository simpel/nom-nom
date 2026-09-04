import SwiftUI

/// Elegant card displaying the average dinner party rating:
/// - Same divided score UI as `MealDetailAverageRatingCard`
/// - Placed above the members list
struct PartyAverageRatingCard: View {
    let party: Party

    @Environment(FoodStore.self) private var store

    private var stats: FoodStore.PartyScoreStats? {
        store.partyAverageScore(partyID: party.id)
    }

    var body: some View {
        SectionCard("Average Rating") {
            if let stats {
                ratedContent(score: stats.score, reaction: stats.reaction)
            } else {
                unratedContent
            }
        }
    }

    @ViewBuilder
    private func ratedContent(score: Double, reaction: Reaction) -> some View {
        let percent = Int((score * 100).rounded())
        HStack(spacing: 0) {
            // Numerical score
            Text("\(percent)%")
                .font(Font.newsreader(.title2, weight: .semibold))
                .foregroundStyle(reaction.text)
                .frame(maxWidth: .infinity, alignment: .center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Fine hairline divider between the two scores
            Rectangle()
                .fill(DS.Color.line.opacity(0.4))
                .frame(width: 1, height: 28)

            // Qualitative verdict score
            Text(reaction.shortLabel)
                .font(Font.newsreader(.title2, weight: .semibold))
                .foregroundStyle(reaction.text)
                .frame(maxWidth: .infinity, alignment: .center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Average rating: \(percent) percent, \(reaction.name)")
    }

    @ViewBuilder
    private var unratedContent: some View {
        HStack(spacing: 0) {
            Text("—")
                .font(Font.newsreader(.title2, weight: .medium))
                .foregroundStyle(DS.Color.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)

            Rectangle()
                .fill(DS.Color.line.opacity(0.4))
                .frame(width: 1, height: 24)

            Text("Unrated")
                .font(Font.newsreader(.title2, weight: .medium))
                .foregroundStyle(DS.Color.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, 8)
        .accessibilityLabel("Average rating: unrated")
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartyAverageRatingCard(party: party)
                .padding()
        }
    }
}
