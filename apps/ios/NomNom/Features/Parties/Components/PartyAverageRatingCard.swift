import SwiftUI

/// The party's average rating over its latest ratings, as a compact ScoreCard.
struct PartyAverageRatingCard: View {
    let party: Party

    @Environment(FoodStore.self) private var store

    @State private var showingScores = false

    private var stats: FoodStore.PartyScoreStats? {
        store.partyAverageScore(partyID: party.id)
    }

    private var countText: String {
        guard let stats else { return "No ratings yet" }
        return stats.count == 1 ? "1 rating" : "\(stats.count) ratings"
    }

    private var isMember: Bool {
        store.isMember(of: party.id)
    }

    var body: some View {
        ScoreCard(
            score: stats?.score,
            verdict: stats?.reaction.shortLabel,
            layout: .compact,
            title: "Average rating",
            count: countText,
            barSegments: stats.map { store.barSegments($0.shares) },
            action: isMember ? { showingScores = true } : nil
        )
        .sheet(isPresented: $showingScores) {
            PartyMemberScoresSheet(party: party)
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartyAverageRatingCard(party: party)
                .padding(DS.Spacing.gutter)
        }
    }
}
