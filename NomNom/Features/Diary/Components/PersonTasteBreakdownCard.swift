import SwiftUI

/// Taste analysis and rating breakdown card in PersonDetailView.
struct PersonTasteBreakdownCard: View {
    let summary: String
    let topTags: [String]
    let ratingCounts: [Reaction: Int]
    let totalRatingsCount: Int

    var body: some View {
        SectionCard(title: "Taste Profile", caption: "AI Insights", color: .purple) {
            VStack(alignment: .leading, spacing: 12) {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                if !topTags.isEmpty {
                    WrappingHStack {
                        ForEach(topTags.prefix(5), id: \.self) { tag in
                            Chip(text: tag, systemImage: "heart.fill", tint: .purple)
                        }
                    }
                }

                if totalRatingsCount > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Rating breakdown")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 6) {
                            ForEach(Reaction.allCases) { reaction in
                                let count = ratingCounts[reaction] ?? 0
                                if count > 0 {
                                    RatingCountBadge(reaction: reaction, count: count)
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}

private struct RatingCountBadge: View {
    let reaction: Reaction
    let count: Int

    var body: some View {
        HStack(spacing: 3) {
            Text("\(reaction.numberLabel): \(count)")
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(reaction.tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(reaction.tint.opacity(0.14)))
    }
}
