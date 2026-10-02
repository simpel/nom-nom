import Foundation

/// Macronutrient distribution as SegmentedBar segments: protein, carbohydrates and fat
/// by their share of the calories, `chart-series` by a stable index per macro (never
/// cycled), grams in the key's label (SegmentedBar's figures are a count or a percent).
enum HealthMacroSegments {
    static func segments(for macros: MacroNutrients) -> [SegmentedBarSegment] {
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

    private static func segment(_ label: String, grams: Double, kcal: Double, series: Int) -> SegmentedBarSegment {
        SegmentedBarSegment(
            label: "\(label) \(format(grams)) g",
            value: kcal.isFinite ? max(kcal, 0) : 0,
            ink: .chart(series)
        )
    }

    private static func format(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        return value.formatted(.number.precision(.fractionLength(0...1)))
    }
}
