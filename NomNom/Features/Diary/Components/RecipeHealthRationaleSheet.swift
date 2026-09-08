import SwiftUI

/// Sheet displaying the in-depth nutritional rationale and cooking method evaluation for a recipe.
struct RecipeHealthRationaleSheet: View {
    let recipe: Recipe
    let healthIndex: HealthIndex

    @Environment(\.dismiss) private var dismiss
    @State private var showingExplainer = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.sectionCompact) {
                    // 1. High-impact score hero card
                    scoreHeroCard

                    // 2. Plain editorial explanation sentence
                    rationaleSection

                    // 3. Cooking technique impact (above bar charts)
                    if let impact = healthIndex.breakdown?.cookingImpact, !impact.isEmpty {
                        cookingImpactSection(impact)
                    }

                    // 4. Macronutrient distribution infographic
                    if let macros = healthIndex.breakdown?.macros {
                        HealthMacroDistributionCard(macros: macros)
                    }

                    // 5. Nutritional highlights
                    if let positives = healthIndex.breakdown?.positives, !positives.isEmpty {
                        positivesSection(positives)
                    }

                    // 6. Methodology explainer button
                    explainerButton
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("Health Rationale", displayMode: .inline)
            .sheetCancelToolbar()
            .sheet(isPresented: $showingExplainer) {
                RecipeHealthExplainerSheet()
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var scoreHeroCard: some View {
        HStack(spacing: 0) {
            Text("\(healthIndex.score)")
                .font(Font.newsreader(size: 46, weight: .bold))
                .foregroundStyle(healthIndex.scoreColor)
                .frame(maxWidth: .infinity, alignment: .center)

            Rectangle()
                .fill(DS.Color.line.opacity(0.4))
                .frame(width: 1, height: 42)

            Text(healthIndex.verdict)
                .font(Font.newsreader(size: 26, weight: .bold))
                .foregroundStyle(healthIndex.scoreColor)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            healthIndex.scoreColor.opacity(0.12),
                            healthIndex.scoreColor.opacity(0.04),
                            DS.Color.panel
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .strokeBorder(healthIndex.scoreColor.opacity(0.25), lineWidth: 1)
                }
        }
    }

    @ViewBuilder
    private var rationaleSection: some View {
        Text(healthIndex.rationale)
            .font(.body)
            .foregroundStyle(DS.Color.textPrimary)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func cookingImpactSection(_ impact: String) -> some View {
        SectionCard("Cooking Technique") {
            Text(impact)
                .font(.subheadline)
                .foregroundStyle(DS.Color.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func positivesSection(_ items: [String]) -> some View {
        SectionCard("Nutritional Highlights", color: DS.Color.Pine.pine600) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: DS.Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DS.Color.Pine.pine600)
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

    @ViewBuilder
    private var explainerButton: some View {
        AppButton(
            "How is this score calculated?",
            icon: .system("info.circle"),
            variant: .neutral,
            style: .outlined,
            size: .md,
            isFullWidth: true
        ) {
            showingExplainer = true
        }
        .padding(.top, DS.Spacing.xs)
    }
}
