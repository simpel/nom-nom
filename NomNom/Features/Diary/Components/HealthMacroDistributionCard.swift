import SwiftUI

/// Infographic card displaying the macronutrient distribution (Protein, Carbs, Fat, Calories)
/// and key nutritional highlights unified in a single calm section.
struct HealthMacroDistributionCard: View {
    let macros: MacroNutrients?
    var positives: [String]? = nil

    private static let proteinColor = Color(red: 0.16, green: 0.52, blue: 0.88)
    private static let carbsColor = Color(red: 0.94, green: 0.54, blue: 0.15)
    private static let fatColor = Color(red: 0.64, green: 0.32, blue: 0.72)

    var body: some View {
        SectionCard(
            "Macronutrients",
            caption: macros?.calories != nil ? "\(macros!.calories!) kcal / serving" : nil
        ) {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                // 1. Macronutrient bars (if macros are provided)
                if let macros {
                    VStack(spacing: DS.Spacing.md) {
                        // Segmented overview bar if multiple macros exist
                        if macros.totalMacroCalories > 0 {
                            segmentedMacroBar(macros)
                        }

                        // Individual macro data rows
                        VStack(spacing: 12) {
                            if let protein = macros.proteinGrams {
                                macroDataRow(
                                    title: "Protein",
                                    amount: "\(formatNumber(protein))g",
                                    kcal: "\(Int((protein * 4).rounded())) kcal",
                                    color: Self.proteinColor
                                )
                            }

                            if let carbs = macros.carbsGrams {
                                macroDataRow(
                                    title: "Carbohydrates",
                                    amount: "\(formatNumber(carbs))g",
                                    kcal: "\(Int((carbs * 4).rounded())) kcal",
                                    color: Self.carbsColor
                                )
                            }

                            if let fat = macros.fatGrams {
                                macroDataRow(
                                    title: "Fat",
                                    amount: "\(formatNumber(fat))g",
                                    kcal: "\(Int((fat * 9).rounded())) kcal",
                                    color: Self.fatColor
                                )
                            }
                        }
                    }
                }

                // 2. Nutritional Highlights (embedded in the same card)
                if let positives, !positives.isEmpty {
                    if macros != nil {
                        Divider()
                            .overlay(DS.Color.line.opacity(0.35))
                            .padding(.vertical, 4)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("HIGHLIGHTS")
                            .font(.caption2.weight(.bold))
                            .tracking(0.5)
                            .foregroundStyle(DS.Color.textSecondary)

                        ForEach(positives, id: \.self) { item in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Circle()
                                    .fill(DS.Color.Pine.pine600)
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 2)

                                Text(item)
                                    .font(.subheadline)
                                    .foregroundStyle(DS.Color.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            print("[HEALTH_DEBUG] HealthMacroDistributionCard appeared:")
            print("[HEALTH_DEBUG] - Calories: \(macros?.calories?.description ?? "nil")")
            print("[HEALTH_DEBUG] - Protein: \(macros?.proteinGrams?.description ?? "nil")g")
            print("[HEALTH_DEBUG] - Carbs: \(macros?.carbsGrams?.description ?? "nil")g")
            print("[HEALTH_DEBUG] - Fat: \(macros?.fatGrams?.description ?? "nil")g")
            print("[HEALTH_DEBUG] - Positives count: \(positives?.count ?? 0)")
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func segmentedMacroBar(_ macros: MacroNutrients) -> some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let pRatio = safeRatio(macros.proteinRatio)
            let cRatio = safeRatio(macros.carbsRatio)
            let fRatio = safeRatio(macros.fatRatio)

            HStack(spacing: 2) {
                if pRatio > 0 {
                    Capsule()
                        .fill(Self.proteinColor)
                        .frame(width: max(4, totalWidth * pRatio))
                }

                if cRatio > 0 {
                    Capsule()
                        .fill(Self.carbsColor)
                        .frame(width: max(4, totalWidth * cRatio))
                }

                if fRatio > 0 {
                    Capsule()
                        .fill(Self.fatColor)
                        .frame(width: max(4, totalWidth * fRatio))
                }
            }
        }
        .frame(height: 8)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func macroDataRow(
        title: String,
        amount: String,
        kcal: String,
        color: Color
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)

                Text(title)
                    .font(.subheadline.weight(.medium))
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
        .padding(.vertical, 1)
    }

    private func safeRatio(_ ratio: Double) -> CGFloat {
        guard ratio.isFinite, !ratio.isNaN else { return 0 }
        return CGFloat(min(1.0, max(0.0, ratio)))
    }

    private func formatNumber(_ value: Double) -> String {
        guard value.isFinite, !value.isNaN else { return "0" }
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }
}
