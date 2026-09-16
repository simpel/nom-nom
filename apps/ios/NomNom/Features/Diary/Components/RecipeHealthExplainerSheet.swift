import SwiftUI

/// Explainer modal detailing how the 1–100 Recipe Health Index is calculated.
/// Based on validated nutritional profiling frameworks (Food Compass & Healthy Cooking Index).
struct RecipeHealthExplainerSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.sectionCompact) {
                    introSection
                    tierBreakdownSection
                    cookingImpactSection
                    scienceSection
                    disclaimerSection
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("Health Methodology", displayMode: .inline)
            .sheetCancelToolbar()
            .presentationDetents([.fraction(0.88), .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var introSection: some View {
        Text("The Health Index is a 1–100 score evaluating both the nutrient density of raw ingredients and the chemical transformations from cooking methods.")
            .font(.body)
            .foregroundStyle(DS.Color.textPrimary)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var tierBreakdownSection: some View {
        SectionCard("Score Tiers") {
            VStack(spacing: DS.Spacing.sm) {
                ForEach(HealthTier.allCases) { tier in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(tier.displayName)
                                .font(AppTypography.subHeading)
                                .foregroundStyle(tier.color)

                            Spacer()

                            Text(tier.rangeDescription)
                                .font(.subheadline.monospacedDigit().weight(.medium))
                                .foregroundStyle(DS.Color.textSecondary)
                        }

                        Text(tier.explanation)
                            .font(.subheadline)
                            .foregroundStyle(DS.Color.textSecondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if tier != HealthTier.allCases.last {
                        Divider()
                            .overlay(DS.Color.line.opacity(0.35))
                            .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var cookingImpactSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Why Cooking Matters")
                .font(AppTypography.sectionHeading)
                .foregroundStyle(DS.Color.textPrimary)
                .padding(.horizontal, 4)

            Text("Identical ingredients yield drastically different nutritional profiles depending on preparation. Gentle methods (steaming, poaching, baking) preserve micronutrients and avoid oxidized fats, while deep-frying or high-heat charring significantly reduces the overall score.")
                .font(.body)
                .foregroundStyle(DS.Color.textPrimary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
        .padding(.top, DS.Spacing.xxs)
    }

    @ViewBuilder
    private var scienceSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("The Science Behind the Score")
                .font(AppTypography.sectionHeading)
                .foregroundStyle(DS.Color.textPrimary)
                .padding(.horizontal, 4)

            Text("Calculations are grounded in validated nutritional profiling research, specifically the Tufts Food Compass and the Healthy Cooking Index. The index evaluates dishes across two pillars: ingredient nutrient density (favoring whole vegetables, fiber, and unsaturated fats over refined sugars and saturated fats) and thermal transformation (how heat and preparation alter micronutrient retention and fat oxidation).")
                .font(.body)
                .foregroundStyle(DS.Color.textPrimary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
        .padding(.top, DS.Spacing.xxs)
    }

    @ViewBuilder
    private var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Nutritional Guidance Note")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DS.Color.textTertiary)

            Text("This index offers guidance on nutrient density and cooking quality. All meals have a place in a balanced, enjoyable diet.")
                .font(.caption)
                .foregroundStyle(DS.Color.textTertiary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
        .padding(.top, DS.Spacing.xs)
    }
}
