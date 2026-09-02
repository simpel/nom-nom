import SwiftUI

/// One ranked dish card in the "What to eat" suggestions list.
struct SuggestionRow: View {
    let suggestion: Suggestion
    let rank: Int
    let showScore: Bool

    private var lastServedText: String {
        guard let days = suggestion.daysSinceServed else { return "Never cooked" }
        switch days {
        case 0: return "Today"
        case 1: return "Yesterday"
        case 2...13: return "\(days) days ago"
        case 14...59: return "\(days / 7) weeks ago"
        default: return "\(days / 30) months ago"
        }
    }

    var body: some View {
        NavigationLink {
            RecipeInsightView(suggestion: suggestion)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack(alignment: .topLeading) {
                    RemoteMealPhoto(path: suggestion.photoPath, cornerRadius: AppRadius.photo)
                        .frame(width: 60, height: 60)
                    if rank <= 3 {
                        Text("\(rank)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(DS.Color.accent))
                            .offset(x: -4, y: -4)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(suggestion.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(DS.Color.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Text(lastServedText)
                        if suggestion.timesServed > 0 {
                            Text("·")
                            Text("\(suggestion.timesServed)×")
                                .monospacedDigit()
                        }
                        if showScore {
                            Text("·")
                            Text(String(format: "%.2f", suggestion.score))
                                .monospacedDigit()
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)

                    if !suggestion.verdicts.isEmpty {
                        VerdictStrip(entries: suggestion.verdicts.map {
                            (emoji: $0.emoji, name: $0.name, reaction: $0.reaction)
                        })
                    }

                    if !suggestion.reasons.isEmpty {
                        WrappingHStack {
                            ForEach(suggestion.reasons, id: \.self) { reason in
                                Chip(text: reason, tint: tint(for: reason))
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func tint(for reason: String) -> Color {
        if reason.contains("happy") || reason.contains("hit") || reason.contains("liked") { return Reaction.great.text }
        if reason.contains("Tough") || reason.contains("no") { return Reaction.bad.text }
        if reason.contains("Overdue") || reason.contains("months") { return DS.Color.accentText }
        return DS.Color.textSecondary
    }
}
