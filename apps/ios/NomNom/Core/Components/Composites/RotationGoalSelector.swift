import SwiftUI

/// Standalone rotation goal selector for rating meals: one OptionCell per RotationGoal,
/// label over description, `spacing-2` apart. Tapping the chosen cell clears it.
struct RotationGoalSelector: View {
    @Binding var selection: RotationGoal?

    var body: some View {
        HStack(spacing: DS.Spacing.s2) {
            ForEach(RotationGoal.allCases) { goal in
                let isSelected = selection == goal
                OptionCell(isSelected: isSelected, minHeight: DS.Spacing.s16) {
                    selection = isSelected ? nil : goal
                } label: {
                    OptionCellText(label: goal.label, description: goal.description, isSelected: isSelected)
                }
                .accessibilityLabel([goal.label, goal.description].compactMap { $0 }.joined(separator: ", "))
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: selection)
    }
}

#Preview {
    @Previewable @State var goal: RotationGoal? = .staple

    RotationGoalSelector(selection: $goal)
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
}
