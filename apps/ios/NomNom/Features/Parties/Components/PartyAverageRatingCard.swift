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
        if let stats {
            DividedScoreCard(
                "Average Rating",
                score: String(format: "%.1f", stats.score * 100),
                verdict: stats.reaction.shortLabel,
                color: stats.reaction.text
            )
        } else {
            DividedScoreCard(
                "Average Rating",
                score: "—",
                verdict: "Unrated",
                color: DS.Color.textTertiary
            )
        }
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
