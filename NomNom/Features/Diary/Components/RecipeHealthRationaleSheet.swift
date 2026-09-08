import SwiftUI

/// Sheet displaying the in-depth nutritional rationale and cooking method evaluation for a recipe.
struct RecipeHealthRationaleSheet: View {
    let recipe: Recipe
    let healthIndex: HealthIndex

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Health Rationale")
                        .font(Font.newsreader(.title2, weight: .regular))
                        .foregroundStyle(DS.Color.textPrimary)

                    DividedScoreCard(
                        score: "\(healthIndex.score)",
                        verdict: healthIndex.verdict,
                        color: healthIndex.scoreColor
                    )

                    RecipeHealthDetailContent(healthIndex: healthIndex)
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, 28)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.fraction(0.82), .large])
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
        VStack(alignment: .leading, spacing: 24) {
            narrativeSection

            if let breakdown = healthIndex.breakdown,
               breakdown.macros != nil || !breakdown.positives.isEmpty {
                HealthMacroDistributionCard(
                    macros: breakdown.macros,
                    positives: breakdown.positives
                )
            }

            Button {
                showingExplainer = true
            } label: {
                Label("How this score is calculated", systemImage: "info.circle")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DS.Color.accentText)
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
