import SwiftUI

/// A protocol representing a selectable card option with configurable label, icon, description, and accent tint.
public protocol TactilePickerOption: Identifiable, Equatable {
    var label: String { get }
    var icon: String? { get }
    var description: String? { get }
    var tint: Color { get }
}

public extension TactilePickerOption {
    var icon: String? { nil }
    var description: String? { nil }
    var tint: Color { DS.Color.primary }
}

/// A row of OptionCells, one per option, `spacing-1.5` apart. Effort options draw the
/// BurnerMeter, rotation goals their Badge (README "Colour": "rotation goal is a Badge
/// going `secondary soft` → `primary soft` → `primary solid`"), anything else its icon
/// and/or label and description. Tapping the chosen cell clears it.
struct TactileOptionPicker<Option: TactilePickerOption>: View {
    let options: [Option]
    @Binding var selection: Option?

    var showLabel: Bool = true
    var showIcon: Bool = true
    var showDescription: Bool = true

    init(
        options: [Option],
        selection: Binding<Option?>,
        showLabel: Bool = true,
        showIcon: Bool = true,
        showDescription: Bool = true
    ) {
        self.options = options
        self._selection = selection
        self.showLabel = showLabel
        self.showIcon = showIcon
        self.showDescription = showDescription
    }

    init(
        selection: Binding<Option?>,
        showLabel: Bool = true,
        showIcon: Bool = true,
        showDescription: Bool = true
    ) where Option: CaseIterable {
        self.init(
            options: Array(Option.allCases), selection: selection,
            showLabel: showLabel, showIcon: showIcon, showDescription: showDescription
        )
    }

    var body: some View {
        HStack(spacing: DS.Spacing.s1_5) {
            ForEach(options) { option in
                let isSelected = selection == option
                let isCompact = !(showIcon && option.icon != nil) && !(showDescription && option.description != nil)
                OptionCell(isSelected: isSelected, tint: option.tint, minHeight: isCompact ? DS.Spacing.s12 : DS.Spacing.s16) {
                    selection = isSelected ? nil : option
                } label: {
                    cellContent(option, isSelected: isSelected, isCompact: isCompact)
                }
                .accessibilityLabel(accessibilityText(for: option))
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: selection?.id)
    }

    @ViewBuilder
    private func cellContent(_ option: Option, isSelected: Bool, isCompact: Bool) -> some View {
        let description = showDescription ? option.description : nil
        VStack(spacing: DS.Spacing.s1) {
            if let effort = option as? EffortLevel {
                BurnerMeter(effort: effort)
            } else if let rotation = option as? RotationGoal {
                Badge.rotation(rotation)
            } else if showIcon, let icon = option.icon {
                Image(systemName: icon)
                    .textStyle(.sansLg, tone: nil, weight: .semibold)
                    .foregroundStyle(isSelected ? option.tint : DS.Color.textSecondary)
            }

            if option is RotationGoal {
                EmptyView()
            } else if isCompact, showLabel {
                Text(option.label).textStyle(.sansXl, weight: .semibold, numeric: true)
            } else {
                OptionCellText(label: showLabel ? option.label : "", description: description, isSelected: isSelected)
            }
        }
    }

    private func accessibilityText(for option: Option) -> String {
        var parts: [String] = []
        if showLabel { parts.append(option.label) }
        if showDescription, let desc = option.description { parts.append(desc) }
        return parts.joined(separator: ", ")
    }
}
