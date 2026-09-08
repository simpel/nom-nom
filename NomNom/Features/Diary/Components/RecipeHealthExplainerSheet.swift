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
                    disclaimerSection
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("Health Methodology", displayMode: .inline)
            .sheetCancelToolbar()
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var introSection: some View {
        SectionCard("Overview") {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("Scientific Recipe Profiling")
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)

                Text("The Health Index is a 1–100 score evaluating both the nutrient density of raw ingredients and the chemical transformations from cooking methods.")
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var tierBreakdownSection: some View {
        SectionCard("Score Tiers") {
            VStack(spacing: DS.Spacing.sm) {
                ForEach(HealthTier.allCases) { tier in
                    HStack(alignment: .top, spacing: DS.Spacing.sm) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(tier.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(tier.color)

                                Spacer()

                                Text(tier.rangeDescription)
                                    .font(.caption.monospacedDigit().weight(.medium))
                                    .foregroundStyle(DS.Color.textTertiary)
                            }

                            Text(tier.explanation)
                                .font(.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if tier != HealthTier.allCases.last {
                        Divider()
                            .overlay(DS.Color.line.opacity(0.3))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var cookingImpactSection: some View {
        SectionCard("Preparation & Cooking Methods") {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("Why Cooking Matters")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)

                Text("Identical ingredients yield drastically different nutritional profiles depending on preparation. Gentle methods (steaming, poaching, baking) preserve micronutrients and avoid oxidized fats, while deep-frying or high-heat charring significantly reduces the overall score.")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Nutritional Guidance Note")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DS.Color.textTertiary)

            Text("This index offers guidance on nutrient density and cooking quality. All meals have a place in a balanced, enjoyable diet.")
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
        }
        .padding(.horizontal, 4)
    }
}
