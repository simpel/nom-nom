import SwiftUI

/// Infographic card displaying the macronutrient distribution (Protein, Carbs, Fat, Calories)
/// as sleek horizontal bar graphs with exact gram and calorie breakdowns.
struct HealthMacroDistributionCard: View {
    let macros: MacroNutrients

    private static let proteinColor = Color(red: 0.16, green: 0.52, blue: 0.88)
    private static let carbsColor = Color(red: 0.94, green: 0.54, blue: 0.15)
    private static let fatColor = Color(red: 0.64, green: 0.32, blue: 0.72)

    var body: some View {
        SectionCard(
            "Macronutrients",
            caption: macros.calories != nil ? "\(macros.calories!) kcal / serving" : nil
        ) {
            VStack(spacing: DS.Spacing.md) {
                // Segmented overview bar if multiple macros exist
                if macros.totalMacroCalories > 0 {
                    segmentedMacroBar
                }

                // Individual macro bar rows
                VStack(spacing: DS.Spacing.sm) {
                    if let protein = macros.proteinGrams {
                        macroBarRow(
                            title: "Protein",
                            amount: "\(formatNumber(protein))g",
                            kcal: "\(Int((protein * 4).rounded())) kcal",
                            ratio: macros.proteinRatio,
                            color: Self.proteinColor
                        )
                    }

                    if let carbs = macros.carbsGrams {
                        macroBarRow(
                            title: "Carbohydrates",
                            amount: "\(formatNumber(carbs))g",
                            kcal: "\(Int((carbs * 4).rounded())) kcal",
                            ratio: macros.carbsRatio,
                            color: Self.carbsColor
                        )
                    }

                    if let fat = macros.fatGrams {
                        macroBarRow(
                            title: "Fat",
                            amount: "\(formatNumber(fat))g",
                            kcal: "\(Int((fat * 9).rounded())) kcal",
                            ratio: macros.fatRatio,
                            color: Self.fatColor
                        )
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var segmentedMacroBar: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            HStack(spacing: 2) {
                if macros.proteinRatio > 0 {
                    Capsule()
                        .fill(Self.proteinColor)
                        .frame(width: max(4, totalWidth * CGFloat(macros.proteinRatio)))
                }

                if macros.carbsRatio > 0 {
                    Capsule()
                        .fill(Self.carbsColor)
                        .frame(width: max(4, totalWidth * CGFloat(macros.carbsRatio)))
                }

                if macros.fatRatio > 0 {
                    Capsule()
                        .fill(Self.fatColor)
                        .frame(width: max(4, totalWidth * CGFloat(macros.fatRatio)))
                }
            }
        }
        .frame(height: 8)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func macroBarRow(
        title: String,
        amount: String,
        kcal: String,
        ratio: Double,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)

                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Text(amount)
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(DS.Color.textPrimary)

                    Text("(\(kcal))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }

            // Horizontal progress bar
            GeometryReader { proxy in
                let width = proxy.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DS.Color.line.opacity(0.35))
                        .frame(height: 8)

                    Capsule()
                        .fill(color)
                        .frame(width: max(8, width * CGFloat(min(1.0, max(0.0, ratio)))), height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    private func formatNumber(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }
}
