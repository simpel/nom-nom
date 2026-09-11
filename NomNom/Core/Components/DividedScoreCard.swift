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

/// Redesigned score component presenting numerical score, qualitative verdict,
/// and an optional historical trend icon as distinct boxes on a single row.
///
/// Fully clickable across the entire row when an action is provided.
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

            boxesRow
        }
    }

    private var boxesRow: some View {
        HStack(spacing: DS.Spacing.xs) {
            // Box 1: Score (X/100 in colors)
            if let action {
                Button(action: action) { scoreBox }.buttonStyle(.plain).disabled(isLoading)
            } else {
                scoreBox
            }

            // Box 2: Verdict in color
            if let action {
                Button(action: action) { verdictBox }.buttonStyle(.plain).disabled(isLoading)
            } else {
                verdictBox
            }

            // Box 3: Global Score
            if let cleanGlobalScore, let globalColor {
                if let globalAction {
                    Button(action: globalAction) { 
                        globalScoreBox(score: cleanGlobalScore, color: globalColor) 
                    }.buttonStyle(.plain)
                } else {
                    globalScoreBox(score: cleanGlobalScore, color: globalColor)
                }
            }

            // Box 4 (Optional): Meal count
            if let mealCount {
                if let action {
                    Button(action: action) { mealsBox(mealCount) }.buttonStyle(.plain).disabled(isLoading)
                } else {
                    mealsBox(mealCount)
                }
            }

            // Box 5 (Optional): Trend indicator when historical score exists
            if let trend {
                if let action {
                    Button(action: action) { trendBox(trend) }.buttonStyle(.plain).disabled(isLoading)
                } else {
                    trendBox(trend)
                }
            }
        }
    }

    private func mealsBox(_ count: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text("\(count)")
                .font(Font.newsreader(.title2, weight: .semibold))
                .foregroundStyle(DS.Color.textPrimary)
                .monospacedDigit()

            Text(count == 1 ? "meal" : "meals")
                .font(Font.newsreader(.subheadline, weight: .medium))
                .foregroundStyle(DS.Color.textSecondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background {
            boxBackground
        }
    }

    private var scoreBox: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(DS.Color.textTertiary)
                    .frame(height: 28) // Matches the approximate height of title2 text
            } else if cleanScore == "—" || Double(cleanScore) == nil {
                Text(cleanScore)
                    .font(Font.newsreader(.title2, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(height: 28)
            } else {
                Text(cleanScore)
                    .font(Font.newsreader(.title2, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(height: 28)

                Text("/100")
                    .font(Font.newsreader(.subheadline, weight: .medium))
                    .foregroundStyle(color.opacity(0.65))
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background {
            boxBackground
        }
    }

    private func globalScoreBox(score: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            if score == "—" || Double(score) == nil {
                Text(score)
                    .font(Font.newsreader(.title2, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(height: 28)
            } else {
                Text(score)
                    .font(Font.newsreader(.title2, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(height: 28)
                
                Text("/100")
                    .font(Font.newsreader(.subheadline, weight: .medium))
                    .foregroundStyle(color.opacity(0.65))
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background {
            boxBackground
        }
    }

    private var verdictBox: some View {
        Group {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(DS.Color.textTertiary)
                    .frame(height: 28)
            } else {
                Text(verdict)
                    .font(Font.newsreader(.title2, weight: .semibold))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(height: 28)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background {
            boxBackground
        }
    }

    private func trendBox(_ trend: ScoreTrend) -> some View {
        HStack(spacing: 4) {
            Image(systemName: trend.systemImage)
                .font(.system(size: 15, weight: .semibold))

            if let delta = trend.delta, delta != 0 {
                Text(delta > 0 ? "+\(delta)" : "\(delta)")
                    .font(Font.newsreader(.subheadline, weight: .semibold))
            }
        }
        .foregroundStyle(trend.color)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity, minHeight: 28)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background {
            boxBackground
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
