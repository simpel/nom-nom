import SwiftUI

/// Explains why a rater likely scored a meal the way they did, based on their historical
/// pattern across dish kinds, ingredients, cuisines, and their personal baseline.
struct MealRaterExplanationSheet: View {
    let raterName: String
    let affinities: [RaterTagAffinity]

    var body: some View {
        NavigationStack {
            ScrollView {
                ProGate {
                    VStack(alignment: .leading, spacing: DS.Spacing.section) {
                        headerSection

                        VStack(alignment: .leading, spacing: DS.Spacing.sectionCompact) {
                            ForEach(affinities) { affinity in
                                SectionCard(heading(for: affinity)) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(affinity.sentence(name: raterName))
                                            .font(.body)
                                            .foregroundStyle(DS.Color.textSecondary)
                                            .lineSpacing(4)
                                            .fixedSize(horizontal: false, vertical: true)

                                        statComparisonRow(affinity)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("Score Insights", displayMode: .inline)
            .sheetCancelToolbar()
            .presentationDetents([.fraction(0.55), .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(raterName)
                .font(Font.newsreader(.title2, weight: .semibold))
                .foregroundStyle(DS.Color.textPrimary)

            Text("Historical rating tendencies relevant to this meal.")
                .font(.subheadline)
                .foregroundStyle(DS.Color.textSecondary)
        }
    }

    private func heading(for affinity: RaterTagAffinity) -> String {
        switch affinity.kind {
        case .dishKind(let name):
            return "Dish Kind: \(name)"
        case .cookingMethod(let name):
            return "Cooking Method: \(name.capitalized)"
        case .ingredient(let name):
            return "Ingredient: \(name.capitalized)"
        case .cuisine(let name):
            return "Cuisine: \(name.capitalized)"
        case .baseline:
            return "Overall Baseline"
        }
    }

    private func statComparisonRow(_ affinity: RaterTagAffinity) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Category Avg")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(DS.Color.textTertiary)
                Text("\(Int((affinity.raterAverage * 100).rounded()))/100")
                    .font(Font.newsreader(.subheadline, weight: .semibold))
                    .foregroundStyle(affinity.delta < 0 ? DS.Color.warningText : DS.Color.primaryText)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Overall Avg")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(DS.Color.textTertiary)
                Text("\(Int((affinity.raterOverallAverage * 100).rounded()))/100")
                    .font(Font.newsreader(.subheadline, weight: .medium))
                    .foregroundStyle(DS.Color.textSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Occasions")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(DS.Color.textTertiary)
                Text("\(affinity.sampleCount)")
                    .font(Font.newsreader(.subheadline, weight: .medium))
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
        .padding(.top, 4)
    }
}
