import SwiftUI

/// Explains why a rater likely scored a meal the way they did, based on their historical
/// pattern of scoring dishes with the same tags/ingredients.
struct MealRaterExplanationSheet: View {
    let raterName: String
    let affinities: [RaterTagAffinity]

    var body: some View {
        NavigationStack {
            ScrollView {
                ProGate {
                    VStack(alignment: .leading, spacing: DS.Spacing.sectionCompact) {
                        ForEach(affinities) { affinity in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(affinity.tag.capitalized)
                                    .font(AppTypography.sectionHeading)
                                    .foregroundStyle(DS.Color.textPrimary)

                                Text(affinity.sentence(name: raterName))
                                    .font(.body)
                                    .foregroundStyle(DS.Color.textSecondary)
                                    .lineSpacing(5)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("Why This Score?", displayMode: .inline)
            .sheetCancelToolbar()
            .presentationDetents([.fraction(0.5), .large])
            .presentationDragIndicator(.visible)
        }
    }
}
