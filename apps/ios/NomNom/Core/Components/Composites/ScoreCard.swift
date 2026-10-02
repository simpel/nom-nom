import SwiftUI

/// ScoreCard's structure (`layout`).
enum ScoreCardLayout: Equatable {
    /// The meal screen's big numeral, delta on its own line, once per screen.
    case hero
    /// Household, health and per-person scores; delta at the end of the score row.
    case compact
}

/// One score readout on a Card: a SectionHeader title, ScoreValue (+ count and delta),
/// a Bar at score/100 and an optional caption. `score` is the normalised 0–1 domain
/// scale (shown as 0–100); `delta` is in display points.
///
/// | layout | Card | gap | ScoreValue | delta |
/// | --- | --- | --- | --- | --- |
/// | `hero` | `md` | `spacing-3.5` | `lg` | own line: Badge `md` + sentence + reference |
/// | `compact` | `sm` | `spacing-3` | `sm` (`md` featured) | Badge `sm` at the end of the score row |
///
/// `variant: .primary` features the score (one per screen, e.g. health): the card is
/// tinted, the title turns `primary-text` semibold and the Bar steps up to `lg`.
/// No rank or leaderboard position on the card; that lives behind `action`, which
/// makes the card a button with Card's chevron. `isLoading` redacts the score.
///
/// ```swift
/// ScoreCard(score: 0.88, delta: -2, deltaText: "from last time this group had it", deltaReference: "(90 on 20 Mar)")
/// ScoreCard(score: 0.82, layout: .compact, title: "Household score", delta: 6, count: "12 meals")
/// ```
struct ScoreCard: View {
    let score: Double?
    var verdict: String?
    var layout: ScoreCardLayout
    var variant: CardVariant?
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
        variant: CardVariant? = nil,
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
        self.variant = variant
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
    private var isFeatured: Bool { variant == .primary }

    private var scoreSize: ScoreValueSize {
        if isHero { return .lg }
        return isFeatured ? .md : .sm
    }

    var body: some View {
        Card(
            size: isHero ? .md : .sm,
            variant: variant,
            spacing: isHero ? DS.Spacing.s3_5 : DS.Spacing.s3,
            action: isLoading ? nil : action
        ) {
            if let title {
                SectionHeader(title: title, systemImage: systemImage, variant: isFeatured ? .primary : nil)
            }

            scoreRow

            if isHero, let delta, !isLoading {
                ScoreCardDeltaLine(delta: delta, text: deltaText, reference: deltaReference)
            }

            // Bar README: "Ground is `track`" (no featured tint, DS-GAPS.md R1b).
            Bar(value: isLoading ? nil : score.map { $0 * 100 }, size: isFeatured ? .lg : .md)
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

    /// bundle.css `__head` (`spacing-3`) with `__aside` (count + compact delta,
    /// `spacing-2`, pushed to the end, `align-self: center`). The numeral and verdict
    /// baseline-align inside ScoreValue; the aside is centred on the row.
    private var scoreRow: some View {
        HStack(alignment: .center, spacing: DS.Spacing.s3) {
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

            Spacer(minLength: 0)

            HStack(spacing: DS.Spacing.s2) {
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
}

/// Hero delta line (bundle.css `__delta`): Badge `md`, then the sentence and its
/// reference, `spacing-2.5` apart.
private struct ScoreCardDeltaLine: View {
    let delta: Int
    let text: String?
    let reference: String?

    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.s2_5) {
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
                    score: 0.64, verdict: "Balanced", layout: .compact, variant: .primary,
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
