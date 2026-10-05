import SwiftUI

/// Standalone cooking time / effort selector: a row of four borderless ChoiceTiles, one
/// per EffortLevel, the range in serif over "minutes" in sans (as the rate-a-meal
/// steps). Tapping the chosen tile clears it.
struct CookingTimeSelector: View {
    @Binding var selection: EffortLevel?

    var body: some View {
        HStack(spacing: DS.Spacing.s2) {
            ForEach(EffortLevel.allCases) { level in
                let isSelected = selection == level
                ChoiceTile(isSelected: isSelected, square: false) {
                    selection = isSelected ? nil : level
                } label: {
                    ChoiceTileText(title: level.range, subtitle: level.description, isSelected: isSelected)
                        .padding(.vertical, DS.Spacing.s2)
                }
                .accessibilityLabel(level.label)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: selection)
    }
}

#Preview {
    @Previewable @State var effort: EffortLevel? = .thirtyTo60

    CookingTimeSelector(selection: $effort)
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
}
