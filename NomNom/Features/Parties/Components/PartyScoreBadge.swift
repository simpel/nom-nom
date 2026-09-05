import SwiftUI

/// Unified, high-craft capsule badge displaying a dinner party's average rating score.
///
/// Combines the percentage and qualitative verdict within a single harmonious pill:
/// `[ 92% | Amazing ]`
struct PartyScoreBadge: View {
    let stats: FoodStore.PartyScoreStats

    var body: some View {
        let percent = Int((stats.score * 100).rounded())

        HStack(spacing: 5) {
            Text("\(percent)%")
                .font(.caption.weight(.bold))
                .monospacedDigit()

            Text("·")
                .font(.caption.weight(.bold))
                .foregroundStyle(stats.reaction.text.opacity(0.6))

            Text(stats.reaction.shortLabel)
                .font(.caption.weight(.semibold))
        }
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: true)
        .foregroundStyle(stats.reaction.text)
        .padding(.horizontal, 8)
        .padding(.vertical, 3.5)
        .background(Capsule().fill(stats.reaction.fill.opacity(0.12)))
        .overlay(
            Capsule().strokeBorder(stats.reaction.fill.opacity(0.24), lineWidth: 0.5)
        )
        .accessibilityLabel("Average rating: \(percent) percent, \(stats.reaction.name)")
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
