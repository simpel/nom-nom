import SwiftUI

/// ScoreValue sizes: numeral step, verdict step.
enum ScoreValueSize: Equatable, CaseIterable {
    /// List rows: numeral only.
    case xs
    case sm
    /// Featured compact.
    case md
    /// Hero and sheet.
    case lg

    var numeral: DS.TextStyle {
        switch self {
        case .xs: return .serifXs
        case .sm: return .serifSm
        case .md: return .serifMd
        case .lg: return .serifXl
        }
    }

    var verdict: DS.TextStyle { .serifSm }

    /// Numeral-to-verdict gap (bundle.css `.nn-score`): `spacing-3`, md `spacing-2.5`, sm `spacing-2`.
    var gap: CGFloat {
        switch self {
        case .xs, .lg: return DS.Spacing.s3
        case .md: return DS.Spacing.s2_5
        case .sm: return DS.Spacing.s2
        }
    }
}

/// What inks the numeral. `accent` (`primary-text`) everywhere except the sheet hero,
/// which takes its reaction step's `-text` ink (DS-GAPS B, "SheetHero reaction ink").
enum ScoreValueInk: Equatable {
    case accent
    case reaction
    /// `pro-text`: the health score, a Pro feature (DS-GAPS A, "ProScoreCard").
    case pro
}

/// A score as type: the numeral in `primary-text` (tabular) and its verdict word,
/// baseline-aligned. Never in a Badge and never on a photo.
struct ScoreValue: View {
    /// Normalised 0–1 (domain scale), or nil when unrated; shown as 0–100.
    let score: Double?
    var verdict: String?
    var size: ScoreValueSize
    var showVerdict: Bool
    var ink: ScoreValueInk

    init(
        score: Double?,
        verdict: String? = nil,
        size: ScoreValueSize = .lg,
        showVerdict: Bool = true,
        ink: ScoreValueInk = .accent
    ) {
        self.score = score
        self.verdict = verdict
        self.size = size
        self.showVerdict = showVerdict
        self.ink = ink
    }

    private var numeralText: String {
        guard let score else { return "\u{2014}" }
        return "\(Int((score * 100).rounded()))"
    }

    private var verdictText: String {
        guard let score else { return "Unrated" }
        return verdict ?? Reaction(score: score).shortLabel
    }

    private var showsVerdict: Bool { showVerdict && size != .xs }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: size.gap) {
            numeral
            if showsVerdict {
                Text(verdictText)
                    .textStyle(size.verdict, tone: score == nil ? .tertiary : .primary)
            }
        }
        .lineLimit(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder private var numeral: some View {
        if let score, ink == .reaction {
            Text(numeralText)
                .textStyle(size.numeral, tone: nil, numeric: true)
                .foregroundStyle(Reaction(score: score).text)
        } else if score != nil, ink == .pro {
            Text(numeralText)
                .textStyle(size.numeral, tone: nil, numeric: true)
                .foregroundStyle(DS.Color.proText)
        } else {
            Text(numeralText)
                .textStyle(size.numeral, tone: score == nil ? .tertiary : .accent, numeric: true)
        }
    }

    private var accessibilityText: String {
        guard score != nil else { return "Unrated" }
        return showsVerdict ? "\(numeralText), \(verdictText)" : "Score \(numeralText)"
    }
}

private struct ScoreValueGallery: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            ForEach(ScoreValueSize.allCases, id: \.self) { ScoreValue(score: 0.83, size: $0) }
            ScoreValue(score: 0.42, verdict: "Divided", size: .md)
            ScoreValue(score: nil, size: .sm)
        }
        .padding(DS.Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.panel)
    }
}

#Preview("Light") { ScoreValueGallery() }
#Preview("Dark") { ScoreValueGallery().preferredColorScheme(.dark) }
