import SwiftUI

/// Standalone cooking time / effort selector: one OptionCell per EffortLevel, label over
/// description, `spacing-1.5` apart. Tapping the chosen cell clears it.
struct CookingTimeSelector: View {
    @Binding var selection: EffortLevel?

    var body: some View {
        HStack(spacing: DS.Spacing.s1_5) {
            ForEach(EffortLevel.allCases) { level in
                let isSelected = selection == level
                OptionCell(isSelected: isSelected, minHeight: DS.Spacing.s16) {
                    selection = isSelected ? nil : level
                } label: {
                    OptionCellText(label: level.label, description: level.description, isSelected: isSelected)
                }
                .accessibilityLabel([level.label, level.description].compactMap { $0 }.joined(separator: ", "))
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
