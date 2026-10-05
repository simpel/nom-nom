// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// A score that is a Pro feature (the health score, the dinner party's insights): ScoreCard's compact readout on ProCard's ground
/// (`pro-soft`, `radius-3xl`, `spacing-5`, `shadow-lg`) with the ProMark, the numeral in
/// `pro-text` and a `pro` Bar.
///
/// With Pro the card is pressable (`action`, a `pro-text` chevron) and opens the detail.
/// Without Pro it shows the main score only (a Bar only when `barSegments` is given): no detail, no tap, and one
/// "Unlock with Pro" button inside the card.
struct ProScoreCard: View {
    let title: String
    let score: Double?
    var verdict: String?
    var isLoading: Bool
    /// Pro only: the Bar split by rater (blocks sum to the score) instead of one fill.
    var barSegments: [BarSegment]?
    var action: (() -> Void)?

    @Environment(EntitlementStore.self) private var entitlements
    @State private var showPaywall = false

    init(
        _ title: String,
        score: Double?,
        verdict: String? = nil,
        isLoading: Bool = false,
        barSegments: [BarSegment]? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.score = score
        self.verdict = verdict
        self.isLoading = isLoading
        self.barSegments = barSegments
        self.action = action
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.xl3, style: .continuous)
    }

    var body: some View {
        if let action, entitlements.hasProAccess, !isLoading {
            Button(action: action) { card(pressable: true) }
                .buttonStyle(AppPressableButtonStyle())
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
        } else {
            card(pressable: false)
        }
    }

    private func card(pressable: Bool) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            HStack(alignment: .top, spacing: DS.Spacing.s3) {
                VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                    ProMark(label: title).accessibilityAddTraits(.isHeader)
                    scoreRow
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if pressable {
                    Image(systemName: "chevron.right")
                        .textStyle(.sansLg, weight: .semibold)
                        .foregroundStyle(DS.Color.proText)
                        .accessibilityHidden(true)
                }
            }
            if let score, !isLoading, entitlements.hasProAccess || barSegments != nil {
                Bar(segments: barSegments ?? [BarSegment(value: score * 100, ink: .color(DS.Color.pro))], max: 100, size: .md, label: title)
                    .accessibilityHidden(true)
            }
            if !entitlements.hasProAccess {
                AppButton("Unlock with Pro", icon: "sparkles", variant: .pro, size: .lg, fullWidth: true) {
                    showPaywall = true
                }
            }
        }
        .padding(DS.Spacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(DS.Color.proSoft))
        .dsShadow(.lg, in: shape)
        .proPaywall(isPresented: $showPaywall)
    }

    @ViewBuilder private var scoreRow: some View {
        if isLoading {
            HStack(spacing: DS.Spacing.s3) {
                SkeletonBone(width: DS.Spacing.s12, height: DS.Spacing.s8)
                SkeletonBone(width: DS.Spacing.s20, height: DS.Spacing.s6)
            }
            .accessibilityLabel("Loading score")
        } else {
            ScoreValue(score: score, verdict: verdict, size: .md, ink: .pro)
        }
    }
}
