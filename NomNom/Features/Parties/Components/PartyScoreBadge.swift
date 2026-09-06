import SwiftUI

/// Unified, high-craft capsule badge displaying a dinner party's average rating score.
///
/// Combines the percentage and qualitative verdict within a single harmonious pill:
/// `[ 92% | Amazing ]`
struct PartyScoreBadge: View {
    let stats: FoodStore.PartyScoreStats

    var body: some View {
        ScoreBadge(stats: stats, format: .both, size: .sm)
    }
}

#Preview {
    NomNomPreview { _ in
        VStack(spacing: 12) {
            PartyScoreBadge(stats: .init(score: 0.95, count: 12, reaction: .amazing))
            PartyScoreBadge(stats: .init(score: 0.76, count: 8, reaction: .great))
            PartyScoreBadge(stats: .init(score: 0.58, count: 5, reaction: .good))
            PartyScoreBadge(stats: .init(score: 0.35, count: 4, reaction: .meh))
        }
        .padding()
    }
}
