import SwiftUI

/// Elegant divided score view with numerical value on the leading side,
/// fine hairline vertical divider, qualitative verdict label on the trailing side,
/// and an optional trailing accessory (e.g. a "Read More" button).
struct DividedScoreView<Accessory: View>: View {
    let score: String
    let verdict: String
    var color: Color = DS.Color.Pine.pine600
    var verticalPadding: CGFloat = 0
    @ViewBuilder var accessory: () -> Accessory

    private var cleanScore: String {
        score.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Numerical scalar score (0–100, no %)
            Text(cleanScore)
                .font(Font.newsreader(.title2, weight: .semibold))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Fine hairline divider
            Rectangle()
                .fill(DS.Color.line.opacity(0.4))
                .frame(width: 1, height: 24)

            // Qualitative verdict
            Text(verdict)
                .font(Font.newsreader(.title2, weight: .semibold))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            accessory()
        }
        .offset(y: 2)
        .padding(.vertical, verticalPadding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(cleanScore), \(verdict)")
    }
}

extension DividedScoreView where Accessory == EmptyView {
    init(
        score: String,
        verdict: String,
        color: Color = DS.Color.Pine.pine600,
        verticalPadding: CGFloat = 0
    ) {
        self.score = score
        self.verdict = verdict
        self.color = color
        self.verticalPadding = verticalPadding
        self.accessory = { EmptyView() }
    }
}

/// Standalone SectionCard wrapper containing a DividedScoreView.
/// Used consistently for Average Ratings (Meals, Parties) and Health Score hero cards.
struct DividedScoreCard<Accessory: View>: View {
    let title: String?
    let score: String
    let verdict: String
    var color: Color
    var caption: String?
    @ViewBuilder var accessory: () -> Accessory

    init(
        _ title: String? = nil,
        score: String,
        verdict: String,
        color: Color = DS.Color.Pine.pine600,
        caption: String? = nil,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) {
        self.title = title
        self.score = score
        self.verdict = verdict
        self.color = color
        self.caption = caption
        self.accessory = accessory
    }

    /// Progress fraction (0–1) for the meter bar, derived from the raw scalar score.
    private var progress: CGFloat? {
        let cleaned = score.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
        guard let value = Int(cleaned) else { return nil }
        return CGFloat(min(max(value, 0), 100)) / 100
    }

    var body: some View {
        Group {
            if let title {
                SectionCard(title, caption: caption) {
                    DividedScoreView(score: score, verdict: verdict, color: color, accessory: accessory)
                }
            } else {
                DividedScoreView(score: score, verdict: verdict, color: color, accessory: accessory)
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                            .fill(DS.Color.panel)
                            .overlay {
                                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                                    .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                            }
                    }
            }
        }
        // Single continuous meter, flush to the card's bottom/side edges with no padding.
        .overlay(alignment: .bottom) {
            if let progress {
                ScoreMeterBar(progress: progress, color: color)
            }
        }
    }
}

extension DividedScoreCard where Accessory == EmptyView {
    init(
        _ title: String? = nil,
        score: String,
        verdict: String,
        color: Color = DS.Color.Pine.pine600,
        caption: String? = nil
    ) {
        self.init(title, score: score, verdict: verdict, color: color, caption: caption) { EmptyView() }
    }
}

/// A single continuous hairline progress track, meant to sit flush against a
/// card's edges via `.overlay(alignment: .bottom)` — never inset as a padded child.
private struct ScoreMeterBar: View {
    let progress: CGFloat
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(color.opacity(0.18))
                Rectangle()
                    .fill(color)
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 4)
    }
}

#Preview {
    NomNomPreview { _ in
        VStack(spacing: 24) {
            DividedScoreCard("Average Rating", score: "75", verdict: "Great", color: Color("ds/reaction/good/text"))
            DividedScoreCard("Health Score", score: "25", verdict: "Indulgent", color: Color("ds/reaction/bad/text"))
            DividedScoreCard("Health Score", score: "88", verdict: "Nutritious", color: DS.Color.Pine.pine600)
            DividedScoreCard(score: "25", verdict: "Indulgent", color: Color("ds/reaction/bad/text")) {
                AppButton("Read More", icon: .system("chevron.right"), iconPosition: .trailing, variant: .neutral, style: .ghost, size: .sm) {}
            }
        }
        .padding()
    }
}
