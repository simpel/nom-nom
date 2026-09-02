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
    var tint: Color { .accentColor }
}

/// A unified, tactile multi-card selector with props for label, icon, and description.
/// Reusable across Cooking Time, Rotation Goal, Taste Verdicts, etc.
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
        self.options = Array(Option.allCases)
        self._selection = selection
        self.showLabel = showLabel
        self.showIcon = showIcon
        self.showDescription = showDescription
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options) { option in
                let isSelected = selection == option
                let hasIcon = showIcon && option.icon != nil
                let hasDescription = showDescription && option.description != nil

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        selection = isSelected ? nil : option
                    }
                } label: {
                    VStack(spacing: 4) {
                        if let effort = option as? EffortLevel {
                            BurnerMeter(effort: effort)
                                .frame(height: 22)
                        } else if let rotation = option as? RotationGoal {
                            RotationPill(goal: rotation, showIcon: false)
                                .frame(height: 22)
                        } else if hasIcon, let icon = option.icon {
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(isSelected ? option.tint : Color.secondary)
                                .frame(height: 20)
                        }

                        if showLabel {
                            if !hasIcon && !hasDescription {
                                Text(option.label)
                                    .font(.system(size: 20, weight: isSelected ? .bold : .semibold, design: .rounded))
                                    .foregroundStyle(isSelected ? option.tint : Color.primary)
                            } else {
                                Text(option.label)
                                    .font(.inter(size: 13, weight: isSelected ? .bold : .semibold))
                                    .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.85))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                        }

                        if hasDescription, let description = option.description {
                            Text(description)
                                .font(.inter(size: 10, weight: .regular))
                                .foregroundStyle(isSelected ? Color.secondary : Color.secondary.opacity(0.8))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: (!hasIcon && !hasDescription) ? 48 : 64)
                    .padding(.vertical, (!hasIcon && !hasDescription) ? 0 : 8)
                    .padding(.horizontal, 4)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.picker, style: .continuous)
                            .fill(
                                isSelected
                                ? option.tint.opacity(0.20)
                                : Color(uiColor: .systemBackground).opacity(0.70)
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.picker, style: .continuous)
                            .strokeBorder(
                                isSelected ? option.tint : Color(uiColor: .separator).opacity(0.25),
                                lineWidth: isSelected ? 1.5 : 0.7
                            )
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityText(for: option))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
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
