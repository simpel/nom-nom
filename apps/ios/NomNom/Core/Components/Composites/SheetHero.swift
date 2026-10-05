import SwiftUI

/// The BottomSheet hero: ScoreValue `lg` over a Bar `md` (the same pair
/// as ScoreCard, `s3` apart) and a `sans-md` `text-secondary` lead whose key
/// figure is set semibold in `primary-text`. Numeral and bar take the score's
/// reaction step (`-text` ink, `-fill` bar): DS-GAPS B, "SheetHero reaction ink".
///
/// ```swift
/// SheetHero(score: 1, lead: "16 above Joel\u{2019}s usual of 84", emphasis: "16 above")
/// ```
struct SheetHero: View {
    /// Normalised 0–1 (domain scale), or nil when unrated.
    let score: Double?
    var verdict: String?
    var lead: String?
    /// The first occurrence of this fragment in `lead` is emphasised.
    var emphasis: String?
    /// `.pro` for the health score (numeral `pro-text`, bar `pro`).
    var ink: ScoreValueInk

    init(score: Double?, verdict: String? = nil, lead: String? = nil, emphasis: String? = nil, ink: ScoreValueInk = .reaction) {
        self.ink = ink
        self.score = score
        self.verdict = verdict
        self.lead = lead
        self.emphasis = emphasis
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            ScoreValue(score: score, verdict: verdict, size: .lg, ink: ink)
            bar.accessibilityHidden(true)
            if let lead, !lead.isEmpty {
                Text(Self.emphasised(lead, fragment: emphasis))
                    .textStyle(.sansMd, tone: .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var bar: some View {
        if let score {
            Bar(
                segments: [BarSegment(value: score * 100, ink: ink == .pro ? .color(DS.Color.pro) : .reaction(Reaction(score: score)))],
                max: 100,
                size: .md,
                label: "\(Int((score * 100).rounded())) out of 100"
            )
        } else {
            Bar(value: nil, size: .md)
        }
    }

    /// `lead` with `fragment` set semibold in `primary-text`.
    static func emphasised(_ lead: String, fragment: String?) -> AttributedString {
        var text = AttributedString(lead)
        guard let fragment, !fragment.isEmpty, let range = text.range(of: fragment) else { return text }
        text[range].foregroundColor = DS.Color.primaryText
        text[range].font = DS.TextStyle.sansMd.font(weight: .semibold)
        return text
    }
}

private struct SheetHeroGallery: View {
    var body: some View {
        VStack(spacing: DS.Spacing.s8) {
            SheetHero(score: 1, lead: "16 above Joel\u{2019}s usual of 84", emphasis: "16 above")
            SheetHero(score: 0.64, verdict: "Balanced", lead: "Plenty of veg and fibre; on the salty side.")
            SheetHero(score: nil, lead: "Nobody has rated this yet.")
        }
        .padding(DS.Spacing.s5)
        .background(DS.Color.sheet)
    }
}

#Preview("Light") { SheetHeroGallery() }
#Preview("Dark") { SheetHeroGallery().preferredColorScheme(.dark) }
