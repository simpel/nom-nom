import SwiftUI

/// ScoreCard's structure.
enum ScoreCardLayout: Equatable {
    /// The meal screen's big numeral, delta on its own line, once per screen.
    case hero
    /// Household, health and per-person scores; delta at the end of the score row.
    case compact
}

/// One score readout: title pre-header, ScoreValue (+ count and delta), a
/// ProgressBar at the score and an optional caption, on a Card. `score` is the
/// normalised 0–1 domain scale (shown as 0–100); `delta` is in display points.
///
/// `featured` (one per screen, e.g. the health score) tints the card `primary`
/// at 10%, turns the title `primary-text`, steps the compact numeral up to
/// `serif-md` and the bar up to `lg` on a `primary` 18% track. `action` makes the
/// card a button with a trailing chevron. `isLoading` shows a redacted placeholder.
///
/// ```swift
/// ScoreCard(score: 0.88, delta: -2, deltaText: "from last time this group had it", deltaReference: "(90 on 20 Mar)")
/// ScoreCard(score: 0.82, layout: .compact, title: "Household score", delta: 6, count: "12 meals")
/// ```
struct ScoreCard: View {
    let score: Double?
    var verdict: String?
    var layout: ScoreCardLayout
    var featured: Bool
    var title: String?
    var systemImage: String?
    var delta: Int?
    var deltaText: String?
    var deltaReference: String?
    var count: String?
    var caption: String?
    var isLoading: Bool
    var action: (() -> Void)?

    init(
        score: Double?,
        verdict: String? = nil,
        layout: ScoreCardLayout = .hero,
        featured: Bool = false,
        title: String? = nil,
        systemImage: String? = nil,
        delta: Int? = nil,
        deltaText: String? = nil,
        deltaReference: String? = nil,
        count: String? = nil,
        caption: String? = nil,
        isLoading: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.score = score
        self.verdict = verdict
        self.layout = layout
        self.featured = featured
        self.title = title
        self.systemImage = systemImage
        self.delta = delta
        self.deltaText = deltaText
        self.deltaReference = deltaReference
        self.count = count
        self.caption = caption
        self.isLoading = isLoading
        self.action = action
    }

    private var isHero: Bool { layout == .hero }

    private var scoreSize: ScoreValueSize {
        if isHero { return .lg }
        return featured ? .md : .sm
    }

    var body: some View {
        Card(
            size: isHero ? .md : .sm,
            featured: featured,
            spacing: isHero ? DS.Spacing.s3_5 : DS.Spacing.s3,
            action: isLoading ? nil : action
        ) {
            if let title {
                SectionHeader(
                    title,
                    systemImage: systemImage,
                    inset: false,
                    variant: featured ? .primary : nil
                )
            }

            scoreRow

            if isHero, let delta, !isLoading {
                ScoreCardDeltaLine(delta: delta, text: deltaText, reference: deltaReference)
            }

            ProgressBar(
                value: isLoading ? nil : score.map { $0 * 100 },
                size: featured ? .lg : .md,
                featured: featured
            )
            // ScoreValue already speaks the score.
            .accessibilityHidden(true)

            if let caption, !isLoading {
                Text(caption)
                    .textStyle(.sansSm, tone: .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var scoreRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s3) {
            Group {
                if isLoading {
                    ScoreValue(score: 0.88, verdict: "Loading", size: scoreSize)
                        .redacted(reason: .placeholder)
                        .accessibilityLabel("Loading score")
                } else {
                    ScoreValue(score: score, verdict: verdict, size: scoreSize)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: DS.Spacing.s2)

            if let count {
                Text(count)
                    .textStyle(.sansSm, tone: .secondary, numeric: true)
                    .lineLimit(1)
            }

            if !isHero, let delta, !isLoading {
                Badge.delta(delta, size: .sm)
            }
        }
    }
}

/// Hero delta line: Badge `md`, then the sentence and its reference.
private struct ScoreCardDeltaLine: View {
    let delta: Int
    let text: String?
    let reference: String?

    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.s2) {
            Badge.delta(delta)
            if text != nil || reference != nil {
                (Text(text ?? "") + Text(reference.map { text == nil ? $0 : " \($0)" } ?? "")
                    .foregroundStyle(DS.Color.textTertiary))
                    .textStyle(.sansSm, tone: .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct ScoreCardGallery: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s4) {
                ScoreCard(
                    score: 0.88, delta: -2,
                    deltaText: "from last time this group had it", deltaReference: "(90 on 20 Mar)",
                    action: {}
                )
                ScoreCard(score: 0.82, layout: .compact, title: "Household score", delta: 6, count: "12 meals")
                ScoreCard(
                    score: 0.64, verdict: "Balanced", layout: .compact, featured: true,
                    title: "Health score", systemImage: "leaf",
                    caption: "Plenty of veg and fibre; on the salty side.", action: {}
                )
                ScoreCard(score: nil, layout: .compact, title: "Average rating", count: "0 meals")
                ScoreCard(score: nil, layout: .compact, title: "Health score", isLoading: true)
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}

#Preview("Light") { ScoreCardGallery() }
#Preview("Dark") { ScoreCardGallery().preferredColorScheme(.dark) }
