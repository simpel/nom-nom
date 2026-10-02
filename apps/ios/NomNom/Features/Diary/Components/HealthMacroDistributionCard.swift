import SwiftUI

/// Macronutrient distribution (protein, carbohydrates, fat by calories) as a
/// SegmentedBar with a legend, plus the recipe's nutritional highlights, in one
/// SectionCard. Calories per serving sit in the section's trailing text.
struct HealthMacroDistributionCard: View {
    let macros: MacroNutrients?
    var positives: [String]? = nil

    private var caloriesText: String? {
        macros?.calories.map { "\($0) kcal / serving" }
    }

    /// `chart-series` by a stable index per macro (protein 1, carbohydrates 2, fat 3),
    /// never cycled. Widths are each macro's share of the calories.
    private var segments: [SegmentedBarSegment] {
        guard let macros else { return [] }
        var result: [SegmentedBarSegment] = []
        if let protein = macros.proteinGrams {
            result.append(segment("Protein", grams: protein, kcal: macros.proteinCalories, series: 0))
        }
        if let carbs = macros.carbsGrams {
            result.append(segment("Carbohydrates", grams: carbs, kcal: macros.carbsCalories, series: 1))
        }
        if let fat = macros.fatGrams {
            result.append(segment("Fat", grams: fat, kcal: macros.fatCalories, series: 2))
        }
        return result
    }

    var body: some View {
        SectionCard("Macronutrients", trailing: caloriesText) {
            if !segments.isEmpty {
                SegmentedBar(segments, legend: .inline, format: .percent, label: "Macronutrient distribution")
            }

            if let positives, !positives.isEmpty {
                if !segments.isEmpty {
                    Rectangle()
                        .fill(DS.Color.line)
                        .frame(height: 1)
                        .accessibilityHidden(true)
                }
                highlights(positives)
            }
        }
    }

    private func highlights(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            SectionHeader(title: "Highlights")
            ForEach(items, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s2) {
                    Circle()
                        .fill(DS.Color.primary)
                        .frame(width: DS.Spacing.s1_5, height: DS.Spacing.s1_5)
                        .accessibilityHidden(true)
                    Text(item)
                        .textStyle(.sansSm)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// SegmentedBar's figures are a count or a percent, so the grams go in the key's label.
    private func segment(_ label: String, grams: Double, kcal: Double, series: Int) -> SegmentedBarSegment {
        SegmentedBarSegment(
            label: "\(label) \(Self.format(grams)) g",
            value: kcal.isFinite ? max(kcal, 0) : 0,
            ink: .chart(series)
        )
    }

    private static func format(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        return value.formatted(.number.precision(.fractionLength(0...1)))
    }
}
