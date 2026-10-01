// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// The two rating blocks of the rate-a-meal flows, stacked `s8` apart:
/// "How was it?" (SectionHeader + TasteScoreSelector) and "How often to repeat"
/// (SectionHeader + RotationGoalSelector). Each header's trailing text is the
/// current choice in `primary-text`.
struct RatingBlocks: View {
    @Binding var reaction: Reaction?
    @Binding var repeatDesire: RotationGoal?

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s8) {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader("How was it?", trailing: reaction?.name, trailingTone: .primary)
                TasteScoreSelector(selection: $reaction)
            }

            VStack(alignment: .leading, spacing: 0) {
                SectionHeader("How often to repeat", trailing: repeatDesire?.title, trailingTone: .primary)
                RotationGoalSelector(selection: $repeatDesire)
            }
        }
    }
}

private struct RatingBlocksPreview: View {
    @State private var reaction: Reaction? = .great
    @State private var repeatDesire: RotationGoal?

    var body: some View {
        RatingBlocks(reaction: $reaction, repeatDesire: $repeatDesire)
            .padding(DS.Spacing.gutter)
            .background(DS.Color.bg)
    }
}

#Preview("Light") { RatingBlocksPreview() }
#Preview("Dark") { RatingBlocksPreview().preferredColorScheme(.dark) }
