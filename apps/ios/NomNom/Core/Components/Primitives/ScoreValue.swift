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
}

/// A score as type: the numeral in `primary-text` (tabular) and its verdict word,
/// baseline-aligned. Never in a Badge and never on a photo.
struct ScoreValue: View {
    /// 0–100, or nil when unrated.
    let score: Double?
    var verdict: String?
    var size: ScoreValueSize
    var showVerdict: Bool

    init(score: Double?, verdict: String? = nil, size: ScoreValueSize = .lg, showVerdict: Bool = true) {
        self.score = score
        self.verdict = verdict
        self.size = size
        self.showVerdict = showVerdict
    }

    private var numeralText: String {
        guard let score else { return "\u{2014}" }
        return "\(Int(score.rounded()))"
    }

    private var verdictText: String {
        guard let score else { return "Unrated" }
        return verdict ?? Reaction(score: score / 100).shortLabel
    }

    private var showsVerdict: Bool { showVerdict && size != .xs }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s2) {
            Text(numeralText)
                .textStyle(size.numeral, tone: score == nil ? .tertiary : .accent, numeric: true)
            if showsVerdict {
                Text(verdictText)
                    .textStyle(size.verdict, tone: score == nil ? .tertiary : .primary)
            }
        }
        .lineLimit(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        guard score != nil else { return "Unrated" }
        return showsVerdict ? "\(numeralText), \(verdictText)" : "Score \(numeralText)"
    }
}

private struct ScoreValueGallery: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            ForEach(ScoreValueSize.allCases, id: \.self) { ScoreValue(score: 83, size: $0) }
            ScoreValue(score: 42, verdict: "Divided", size: .md)
            ScoreValue(score: nil, size: .sm)
        }
        .padding(DS.Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.panel)
    }
}

#Preview("Light") { ScoreValueGallery() }
#Preview("Dark") { ScoreValueGallery().preferredColorScheme(.dark) }
