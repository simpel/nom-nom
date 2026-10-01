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

    private var segments: [SegmentedBarSegment] {
        guard let macros else { return [] }
        var result: [SegmentedBarSegment] = []
        if let protein = macros.proteinGrams {
            result.append(segment("Protein", grams: protein, kcal: macros.proteinCalories, color: DS.Color.chartSeries1))
        }
        if let carbs = macros.carbsGrams {
            result.append(segment("Carbohydrates", grams: carbs, kcal: macros.carbsCalories, color: DS.Color.chartSeries2))
        }
        if let fat = macros.fatGrams {
            result.append(segment("Fat", grams: fat, kcal: macros.fatCalories, color: DS.Color.chartSeries5))
        }
        return result
    }

    var body: some View {
        SectionCard("Macronutrients", trailing: caloriesText) {
            if !segments.isEmpty {
                SegmentedBar(segments, label: "Macronutrient distribution")
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
            SectionHeader("Highlights", inset: false)
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

    private func segment(_ label: String, grams: Double, kcal: Double, color: Color) -> SegmentedBarSegment {
        SegmentedBarSegment(
            value: kcal.isFinite ? max(kcal, 0) : 0,
            color: color,
            label: label,
            valueText: "\(Self.format(grams)) g",
            detail: "\(Int(kcal.rounded())) kcal"
        )
    }

    private static func format(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        return value.formatted(.number.precision(.fractionLength(0...1)))
    }
}
