import SwiftUI

/// Sheet displaying the in-depth nutritional rationale and cooking method evaluation for a recipe.
struct RecipeHealthRationaleSheet: View {
    let recipe: Recipe
    let healthIndex: HealthIndex

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.sectionCompact) {
                    DividedScoreCard(
                        score: "\(healthIndex.score)",
                        verdict: healthIndex.verdict,
                        color: healthIndex.scoreColor
                    )

                    ProGate {
                        RecipeHealthDetailContent(healthIndex: healthIndex)
                    }
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("Health Rationale", displayMode: .inline)
            .sheetCancelToolbar()
            .presentationDetents([.fraction(0.85), .large])
            .presentationDragIndicator(.visible)
        }
    }
}

/// Rationale text, cooking technique impact, and macronutrient breakdown for a recipe's
/// health score. Used inside `RecipeHealthRationaleSheet`.
struct RecipeHealthDetailContent: View {
    let healthIndex: HealthIndex

    @State private var showingExplainer = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.section) {
            narrativeSection

            if let breakdown = healthIndex.breakdown,
               breakdown.macros != nil || !breakdown.positives.isEmpty {
                HealthMacroDistributionCard(
                    macros: breakdown.macros,
                    positives: breakdown.positives
                )
            }

            AppButton(
                "How this score is calculated",
                icon: .system("info.circle"),
                variant: .secondary,
                style: .ghost,
                size: .sm
            ) {
                showingExplainer = true
            }
        }
        .sheet(isPresented: $showingExplainer) {
            RecipeHealthExplainerSheet()
        }
    }

    @ViewBuilder
    private var narrativeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(healthIndex.rationale)
                .font(.body)
                .foregroundStyle(DS.Color.textPrimary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            if let impact = healthIndex.breakdown?.cookingImpact, !impact.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Cooking Technique")
                        .font(AppTypography.sectionHeading)
                        .foregroundStyle(DS.Color.textPrimary)

                    Text(impact)
                        .font(.body)
                        .foregroundStyle(DS.Color.textPrimary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 24)
            }
        }
    }
}
