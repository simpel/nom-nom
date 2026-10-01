import SwiftUI

/// Single member rating row inside MealScoreBreakdownSheet.
/// Displays the member's score along with their contextual preference insights (dish kind, ingredients, baseline).
struct MealMemberScoreRow: View {
    let detail: FoodStore.VerdictDetail
    let affinities: [RaterTagAffinity]
    var onTapExplain: (() -> Void)? = nil

    private var topAffinity: RaterTagAffinity? {
        affinities.first
    }

    var body: some View {
        Button {
            if !affinities.isEmpty {
                onTapExplain?()
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                mainRow

                if let affinity = topAffinity {
                    insightBadge(affinity)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(affinities.isEmpty || onTapExplain == nil)
    }

    private var mainRow: some View {
        HStack(spacing: 12) {
            // Initial circle avatar (Strictly NO EMOJIS)
            ZStack {
                Circle()
                    .fill(DS.Color.panel)
                    .overlay {
                        Circle()
                            .strokeBorder(DS.Color.line.opacity(0.4), lineWidth: 0.5)
                    }
                Text(String(detail.name.prefix(1)).uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .frame(width: 32, height: 32)

            Text(detail.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DS.Color.textPrimary)

            Spacer()

            if let reaction = detail.reaction {
                reactionBadge(reaction)
            } else {
                Text("Pending")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
    }

    private func reactionBadge(_ reaction: Reaction) -> some View {
        let formattedPercent = String(format: "%.1f", reaction.score * 100)
        return HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(formattedPercent)
                .font(Font.newsreader(.subheadline, weight: .semibold))
                .foregroundStyle(reaction.text)
            Text("/100")
                .font(Font.newsreader(.caption2, weight: .medium))
                .foregroundStyle(reaction.text.opacity(0.6))
            Text("•")
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
                .padding(.horizontal, 2)
            Text(reaction.shortLabel)
                .font(.caption.weight(.medium))
                .foregroundStyle(reaction.text)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                .fill(DS.Color.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                        .strokeBorder(DS.Color.line.opacity(0.3), lineWidth: 0.5)
                }
        }
    }

    private func insightBadge(_ affinity: RaterTagAffinity) -> some View {
        HStack(spacing: 6) {
            Text(affinity.shortSummary)
                .font(.caption2.weight(.medium))
                .foregroundStyle(affinity.delta < 0 ? Color("ds/reaction/bad/text") : DS.Color.Pine.pine600)

            if affinities.count > 1 {
                Text("+\(affinities.count - 1) more")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(DS.Color.textTertiary)
        }
        .padding(.leading, 44) // Align with member name after 32pt avatar + 12pt spacing
        .padding(.trailing, 4)
    }
}
