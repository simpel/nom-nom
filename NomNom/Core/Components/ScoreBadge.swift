import SwiftUI

/// Unified score label component.
///
/// Displays score percentages and qualitative verdicts across the app using
/// consistent non-bold typography and borderless capsule styling.
struct ScoreBadge: View {
    let score: Double?
    let percent: Int?
    let reaction: Reaction?
    let format: ScoreBadgeFormat
    let style: ScoreBadgeStyle
    let size: ScoreBadgeSize
    let separator: String

    // MARK: - Initializers

    init(
        score: Double,
        reaction: Reaction? = nil,
        format: ScoreBadgeFormat = .scoreOnly,
        style: ScoreBadgeStyle = .tinted,
        size: ScoreBadgeSize = .sm,
        separator: String = "·"
    ) {
        self.score = score
        self.percent = Int((score * 100).rounded())
        self.reaction = reaction ?? Self.derivedReaction(for: score)
        self.format = format
        self.style = style
        self.size = size
        self.separator = separator
    }

    init(
        percent: Int,
        reaction: Reaction? = nil,
        format: ScoreBadgeFormat = .scoreOnly,
        style: ScoreBadgeStyle = .tinted,
        size: ScoreBadgeSize = .sm,
        separator: String = "·"
    ) {
        let normalized = Double(percent) / 100.0
        self.score = normalized
        self.percent = percent
        self.reaction = reaction ?? Self.derivedReaction(for: normalized)
        self.format = format
        self.style = style
        self.size = size
        self.separator = separator
    }

    init(
        stats: FoodStore.PartyScoreStats,
        format: ScoreBadgeFormat = .both,
        style: ScoreBadgeStyle = .tinted,
        size: ScoreBadgeSize = .sm,
        separator: String = "·"
    ) {
        self.score = stats.score
        self.percent = Int((stats.score * 100).rounded())
        self.reaction = stats.reaction
        self.format = format
        self.style = style
        self.size = size
        self.separator = separator
    }

    init(
        reaction: Reaction,
        format: ScoreBadgeFormat = .verdictOnly,
        style: ScoreBadgeStyle = .tinted,
        size: ScoreBadgeSize = .sm
    ) {
        self.score = reaction.score
        self.percent = Int((reaction.score * 100).rounded())
        self.reaction = reaction
        self.format = format
        self.style = style
        self.size = size
        self.separator = "·"
    }

    // MARK: - View Body

    var body: some View {
        HStack(spacing: size.itemSpacing) {
            switch format {
            case .scoreOnly:
                percentText
            case .both:
                percentText
                separatorText
                verdictText
            case .verdictOnly:
                verdictText
            }
        }
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: true)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(backgroundColor)
        .clipShape(Capsule())
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var percentText: some View {
        if let percent {
            Text("\(percent)%")
                .font(size.font)
                .monospacedDigit()
                .foregroundStyle(foregroundColor)
        }
    }

    @ViewBuilder
    private var separatorText: some View {
        Text(separator)
            .font(size.font)
            .foregroundStyle(foregroundColor.opacity(0.6))
    }

    @ViewBuilder
    private var verdictText: some View {
        if let reaction {
            Text(reaction.shortLabel)
                .font(size.font)
                .foregroundStyle(foregroundColor)
        }
    }

    // MARK: - Styling Logic

    private var foregroundColor: Color {
        switch style {
        case .tinted, .ghost:
            return reaction?.text ?? DS.Color.textPrimary
        case .subtle:
            return DS.Color.textSecondary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .ghost:
            return .clear
        case .tinted:
            return (reaction?.fill ?? DS.Color.accent).opacity(0.14)
        case .subtle:
            return DS.Color.sunken
        }
    }

    private var accessibilityDescription: String {
        switch format {
        case .scoreOnly:
            return "\(percent ?? 0) percent"
        case .both:
            return "\(percent ?? 0) percent, \(reaction?.name ?? "")"
        case .verdictOnly:
            return reaction?.name ?? ""
        }
    }

    // MARK: - Helpers

    private static func derivedReaction(for score: Double) -> Reaction {
        if score >= 0.85 { return .amazing }
        if score >= 0.70 { return .great }
        if score >= 0.50 { return .good }
        if score >= 0.30 { return .meh }
        if score >= 0.15 { return .bad }
        return .inedible
    }
}

/// Convenience alias matching user nomenclature.
typealias ScoreLabel = ScoreBadge

#Preview("ScoreBadge Variations") {
    NomNomPreview { _ in
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ScoreBadge(percent: 75, size: .sm)
                ScoreBadge(percent: 80, size: .sm)
                ScoreBadge(percent: 92, size: .sm)
            }

            HStack(spacing: 8) {
                ScoreBadge(stats: .init(score: 0.83, count: 10, reaction: .great), format: .both, size: .sm)
                ScoreBadge(stats: .init(score: 0.95, count: 12, reaction: .amazing), format: .both, size: .sm)
            }

            HStack(spacing: 8) {
                ScoreBadge(reaction: .great, size: .sm)
                ScoreBadge(reaction: .amazing, size: .sm)
                ScoreBadge(reaction: .meh, size: .sm)
            }
        }
        .padding()
    }
}
