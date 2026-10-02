import SwiftUI

/// A compact taste reaction selector (−1…5) for household eater rows: six OptionCells in
/// the reaction's colours, `spacing-1` apart, each a `spacing-7` square minimum with a
/// `sans-xs` semibold tabular numeral (`text-secondary` at rest, the reaction's `text`
/// when chosen). Tapping the chosen cell clears it.
struct TactileTasteSelector: View {
    @Binding var selection: Reaction?

    var body: some View {
        HStack(spacing: DS.Spacing.s1) {
            ForEach(Reaction.allCases) { reaction in
                let isSelected = selection == reaction
                OptionCell(isSelected: isSelected, tint: reaction.fill, minHeight: DS.Spacing.s7) {
                    selection = isSelected ? nil : reaction
                } label: {
                    Text(TasteScoreSelector.glyph(for: reaction))
                        .textStyle(.sansXs, tone: nil, weight: .semibold, numeric: true)
                        .foregroundStyle(isSelected ? reaction.text : DS.Color.textSecondary)
                        .frame(minWidth: DS.Spacing.s5)
                }
                .fixedSize()
                .accessibilityLabel("\(reaction.numberLabel): \(reaction.name)")
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: selection)
    }
}

#Preview {
    @Previewable @State var reaction: Reaction? = .great

    TactileTasteSelector(selection: $reaction)
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
}
