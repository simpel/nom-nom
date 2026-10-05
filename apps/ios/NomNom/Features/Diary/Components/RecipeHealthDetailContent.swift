import SwiftUI

/// Inside the health sheet's ProSection: the rationale (`sans-md`), then blocks split
/// by `line` rules — Cooking technique, Macronutrients (kcal per serving trailing, a
/// SegmentedBar with an inline key, percent) and Highlights beside Watch out for.
struct RecipeHealthDetailContent: View {
    let healthIndex: HealthIndex

    private var breakdown: HealthBreakdown? { healthIndex.breakdown }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            Text(healthIndex.rationale)
                .textStyle(.sansMd)
                .fixedSize(horizontal: false, vertical: true)

            if let impact = breakdown?.cookingImpact, !impact.isEmpty {
                block("Cooking technique") {
                    Text(impact)
                        .textStyle(.sansMd, tone: .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let macros = breakdown?.macros {
                let segments = HealthMacroSegments.segments(for: macros)
                if !segments.isEmpty {
                    block("Macronutrients", trailing: macros.calories.map { "\($0) kcal / serving" }) {
                        SegmentedBar(segments, legend: .inline, format: .percent, label: "Macronutrient distribution")
                    }
                }
            }

            let positives = breakdown?.positives ?? []
            let considerations = breakdown?.considerations ?? []
            if !positives.isEmpty || !considerations.isEmpty {
                HStack(alignment: .top, spacing: DS.Spacing.s5) {
                    if !positives.isEmpty {
                        HealthBulletList(title: "Highlights", items: positives, dot: DS.Color.primary)
                    }
                    if !considerations.isEmpty {
                        HealthBulletList(title: "Watch out for", items: considerations, dot: DS.Color.warning)
                    }
                }
                .padding(.top, DS.Spacing.s4)
                .overlay(alignment: .top) { rule }
            }
        }
    }

    private func block<Content: View>(
        _ title: String,
        trailing: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            SectionHeader(title: title, trailing: trailing)
            content()
        }
        .padding(.top, DS.Spacing.s4)
        .overlay(alignment: .top) { rule }
    }

    private var rule: some View {
        Rectangle()
            .fill(DS.Color.line)
            .frame(height: DS.BorderWidth.hairline)
            .accessibilityHidden(true)
    }
}

/// A titled list of short points with a coloured dot (`spacing-1.5`) before each.
struct HealthBulletList: View {
    let title: String
    let items: [String]
    let dot: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            SectionHeader(title: title)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s2) {
                    Circle()
                        .fill(dot)
                        .frame(width: DS.Spacing.s1_5, height: DS.Spacing.s1_5)
                        .accessibilityHidden(true)
                    Text(item)
                        .textStyle(.sansSm)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
