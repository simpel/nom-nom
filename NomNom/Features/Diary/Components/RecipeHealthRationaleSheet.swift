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
                VStack(spacing: DS.Spacing.sectionCompact) {
                    scoreHeroCard
                    rationaleSection

                    if let breakdown = healthIndex.breakdown {
                        if !breakdown.positives.isEmpty {
                            positivesSection(breakdown.positives)
                        }

                        if !breakdown.considerations.isEmpty {
                            considerationsSection(breakdown.considerations)
                        }

                        if let impact = breakdown.cookingImpact, !impact.isEmpty {
                            cookingImpactSection(impact)
                        }
                    }

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
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                Text("\(healthIndex.score)")
                    .font(Font.newsreader(.largeTitle, weight: .bold))
                    .foregroundStyle(healthIndex.scoreColor)
                    .frame(maxWidth: .infinity, alignment: .center)

                Rectangle()
                    .fill(DS.Color.line.opacity(0.4))
                    .frame(width: 1, height: 36)

                Text(healthIndex.verdict)
                    .font(Font.newsreader(.title, weight: .semibold))
                    .foregroundStyle(healthIndex.scoreColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.vertical, 12)
        }
        .background {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(DS.Color.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                }
        }
    }

    @ViewBuilder
    private var rationaleSection: some View {
        SectionCard("Nutritional Overview") {
            Text(healthIndex.rationale)
                .font(.body)
                .foregroundStyle(DS.Color.textPrimary)
                .lineSpacing(4)
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
    private func considerationsSection(_ items: [String]) -> some View {
        SectionCard("Points of Moderation", color: DS.Color.Stone.stone600) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: DS.Spacing.xs) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DS.Color.Stone.stone600)
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
    private func cookingImpactSection(_ impact: String) -> some View {
        SectionCard("Cooking Technique Impact") {
            Text(impact)
                .font(.subheadline)
                .foregroundStyle(DS.Color.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
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
