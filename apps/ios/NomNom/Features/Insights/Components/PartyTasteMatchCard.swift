import SwiftUI

/// Card displaying how well each member's taste ratings align with the meals served to the party,
/// their satisfaction trajectory (trending up, down, or flat), and AI-generated mismatch explanations.
/// Tapping a member triggers `onSelectMember` to view person-specific insights for this party.
struct PartyTasteMatchCard: View {
    let matches: [MemberTasteMatch]
    var onSelectMember: ((MemberTasteMatch) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Taste Match")
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)

                Text("How each member's ratings align with the food served.")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            if matches.isEmpty {
                Text("Not enough rated meals to calculate matches.")
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DS.Spacing.xs)
            } else {
                VStack(spacing: DS.Spacing.md) {
                    ForEach(matches, id: \.id) { item in
                        if let onSelectMember {
                            Button {
                                onSelectMember(item)
                            } label: {
                                memberRow(item)
                            }
                            .buttonStyle(.plain)
                        } else {
                            memberRow(item)
                        }

                        if item.id != matches.last?.id {
                            Divider()
                                .overlay(DS.Color.line)
                        }
                    }
                }
            }
        }
        .padding(DS.Spacing.md)
        .background(DS.Color.panel)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    private func memberRow(_ item: MemberTasteMatch) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            HStack(alignment: .center, spacing: DS.Spacing.sm) {
                PartyAvatar(
                    name: item.name,
                    size: 28
                )

                Text(item.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DS.Color.textPrimary)

                Spacer()

                if let trend = item.trend {
                    trendBadge(trend)
                }

                Text("\(item.matchScore)% Match")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(matchTextColor(item.matchScore))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(matchBgColor(item.matchScore))
                    .clipShape(Capsule())
            }

        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func trendBadge(_ trend: TasteTrendDirection) -> some View {
        HStack(spacing: 3) {
            Image(systemName: trend.systemImage)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(trendColor(trend))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(trendColor(trend).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .accessibilityLabel(trend.label)
    }

    private func trendColor(_ trend: TasteTrendDirection) -> Color {
        switch trend {
        case .up: return Color.green
        case .down: return Color.red
        case .flat: return DS.Color.textSecondary
        }
    }

    private func matchTextColor(_ score: Int) -> Color {
        if score >= 80 { return Color.green }
        if score >= 60 { return DS.Color.accentText }
        return DS.Color.textSecondary
    }

    private func matchBgColor(_ score: Int) -> Color {
        if score >= 80 { return Color.green.opacity(0.12) }
        if score >= 60 { return DS.Color.accentSoft }
        return DS.Color.sunken
    }
}

#Preview {
    VStack(spacing: 16) {
        PartyTasteMatchCard(matches: [
            MemberTasteMatch(
                ref: .account(UUID()),
                name: "Anna",
                matchScore: 88,
                ratedMealsCount: 6,
                trend: .down,
                trendDelta: -12,
                explanation: "Anna loves pasta nights but consistently rates the party's heavier BBQ and spicy dishes lower than the group."
            ),
            MemberTasteMatch(
                ref: .account(UUID()),
                name: "Joel",
                matchScore: 95,
                ratedMealsCount: 8,
                trend: .up,
                trendDelta: 10,
                explanation: "Broad palate across all party meals with strong affinity for grilled dishes."
            )
        ])
    }
    .padding()
    .background(DS.Color.bg)
}
