import SwiftUI

/// How a party's meals split across health tiers: a SegmentedBar whose breakdown is a
/// RatingList, one row per tier with its percentage. Health tiers are not taste data,
/// so they take `chart-series` by the tier's stable index, not the reaction ramp.
struct PartyHealthDistributionCard: View {
    /// Each tier's share, 0–1.
    let distribution: [HealthTier: Double]

    private var segments: [SegmentedBarSegment] {
        HealthTier.allCases.enumerated().map { index, tier in
            SegmentedBarSegment(label: tier.displayName, value: distribution[tier] ?? 0, ink: .chart(index))
        }
    }

    var body: some View {
        SegmentedBar(segments, legend: .rows, format: .percent, title: "Dietary balance")
    }
}

#Preview {
    NomNomPreview { _ in
        PartyHealthDistributionCard(distribution: [.nutritious: 0.4, .balanced: 0.35, .moderate: 0.2, .indulgent: 0.05])
            .padding(DS.Spacing.gutter)
            .background(DS.Color.bg)
    }
}
