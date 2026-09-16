import SwiftUI

/// Trend direction comparing the current meal score to past occasions for the same recipe.
enum ScoreTrend: Hashable {
    case up(delta: Int? = nil)
    case down(delta: Int? = nil)
    case neutral(delta: Int? = nil)

    var delta: Int? {
        switch self {
        case .up(let d), .down(let d), .neutral(let d):
            return d
        }
    }

    var systemImage: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .up: return DS.Color.Pine.pine600
        case .down: return Color("ds/reaction/bad/text")
        case .neutral: return DS.Color.textSecondary
        }
    }
}

/// Redesigned score component presenting the numerical score and qualitative verdict on
/// a top row, with a spectrum indicator gradient bar on a row below — both inside a
/// single card. Optional accessories (global rank, meal count, trend) sit at the right
/// of the top row.
///
/// Fully clickable across the score/verdict/indicator area when an action is provided.
struct DividedScoreCard: View {
    let title: String?
    let score: String
    let verdict: String
    var color: Color
    var trend: ScoreTrend?
    var mealCount: Int?
    var globalScore: String?
    var globalColor: Color?
    var action: (() -> Void)?
    var globalAction: (() -> Void)?
    var isLoading: Bool

    init(
        _ title: String? = nil,
        score: String,
        verdict: String,
        color: Color = DS.Color.Pine.pine600,
        trend: ScoreTrend? = nil,
        mealCount: Int? = nil,
        globalScore: String? = nil,
        globalColor: Color? = nil,
        isLoading: Bool = false,
        action: (() -> Void)? = nil,
        globalAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.score = score
        self.verdict = verdict
        self.color = color
        self.trend = trend
        self.mealCount = mealCount
        self.globalScore = globalScore
        self.globalColor = globalColor
        self.isLoading = isLoading
        self.action = action
        self.globalAction = globalAction
    }

    private var cleanScore: String {
        score.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
    }

    /// Whole-number scores drop their decimal (e.g. "80.0" → "80").
    private var displayScore: String {
        guard let value = Double(cleanScore) else { return cleanScore }
        guard value.truncatingRemainder(dividingBy: 1) == 0 else { return cleanScore }
        return String(Int(value))
    }

    private var cleanGlobalScore: String? {
        globalScore?.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(0.5)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.leading, 2)
            }

            card
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            topRow
            indicatorRow
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background {
            boxBackground
        }
    }

    private var topRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            scoreVerdictGroup

            Spacer(minLength: 8)

            if let cleanGlobalScore, cleanGlobalScore != "—", let globalColor {
                if let globalAction {
                    Button(action: globalAction) {
                        globalScoreChip(score: cleanGlobalScore, color: globalColor)
                    }.buttonStyle(.plain)
                } else {
                    globalScoreChip(score: cleanGlobalScore, color: globalColor)
                }
            }

            if let mealCount {
                mealsLabel(mealCount)
            }

            if let trend {
                trendLabel(trend)
            }
        }
    }

    private var indicatorRow: some View {
        Group {
            if let action {
                Button(action: action) { indicatorBar }.buttonStyle(.plain).disabled(isLoading)
            } else {
                indicatorBar
            }
        }
    }

    /// Score number and verdict word grouped together, e.g. "62 Balanced".
    private var scoreVerdictGroup: some View {
        Group {
            if let action {
                Button(action: action) { scoreVerdictContent }.buttonStyle(.plain).disabled(isLoading)
            } else {
                scoreVerdictContent
            }
        }
    }

    private var scoreVerdictContent: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(DS.Color.textTertiary)
                    .frame(height: 28)
            } else {
                Text(displayScore)
                    .font(Font.newsreader(.title2, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(height: 28)

                Text(verdict)
                    .font(Font.newsreader(.title2, weight: .semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .frame(height: 28)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    /// Horizontal indulgent → nourishing gradient track with a thumb marking where the score falls.
    private var indicatorProgress: Double? {
        guard let value = Double(cleanScore) else { return nil }
        return max(0, min(1, value / 100))
    }

    private var indicatorBar: some View {
        GeometryReader { geo in
            let trackHeight: CGFloat = 8
            let thumbSize: CGFloat = 16

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("ds/reaction/bad/fill"),
                                Color("ds/reaction/meh/fill"),
                                Color("ds/reaction/good/fill"),
                                DS.Color.Pine.pine400
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(indicatorProgress == nil ? 0.35 : 1)
                    .frame(height: trackHeight)

                if let indicatorProgress {
                    Circle()
                        .fill(isLoading ? DS.Color.textTertiary : color)
                        .overlay {
                            Circle().strokeBorder(DS.Color.panel, lineWidth: 2)
                        }
                        .frame(width: thumbSize, height: thumbSize)
                        .offset(x: indicatorProgress * max(0, geo.size.width - thumbSize))
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 20)
    }

    private func mealsLabel(_ count: Int) -> some View {
        let text = HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text("\(count)")
                .font(Font.newsreader(.subheadline, weight: .semibold))
                .foregroundStyle(DS.Color.textPrimary)
                .monospacedDigit()

            Text(count == 1 ? "meal" : "meals")
                .font(Font.newsreader(.footnote, weight: .medium))
                .foregroundStyle(DS.Color.textSecondary)
        }
        .lineLimit(1)

        return Group {
            if let action {
                Button(action: action) { text }.buttonStyle(.plain).disabled(isLoading)
            } else {
                text
            }
        }
    }

    private func trendLabel(_ trend: ScoreTrend) -> some View {
        let content = HStack(spacing: 4) {
            Image(systemName: trend.systemImage)
                .font(.system(size: 13, weight: .semibold))

            if let delta = trend.delta, delta != 0 {
                Text(delta > 0 ? "+\(delta)" : "\(delta)")
                    .font(Font.newsreader(.footnote, weight: .semibold))
            }
        }
        .foregroundStyle(trend.color)
        .lineLimit(1)

        return Group {
            if let action {
                Button(action: action) { content }.buttonStyle(.plain).disabled(isLoading)
            } else {
                content
            }
        }
    }

    private func globalScoreChip(score: String, color: Color) -> some View {
        Text(score)
            .font(Font.newsreader(.subheadline, weight: .semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background {
                Capsule()
                    .fill(color.opacity(0.14))
            }
    }

    private var boxBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
            .fill(DS.Color.panel)
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                    .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
            }
    }
}
