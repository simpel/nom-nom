import SwiftUI

/// Standardized single-hue pill weight representation for RotationGoal:
/// - `oneAndDone`: outline (`lineStrong` border, `textTertiary` label)
/// - `sometimes`: `accentSoft` fill with `accentText` label
/// - `staple`: `accent` fill with `panel` label
struct RotationPill: View {
    let goal: RotationGoal
    var showIcon: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            if showIcon, let icon = goal.icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(goal.label)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(foregroundColor)
        .background {
            Capsule().fill(backgroundColor)
        }
        .overlay {
            Capsule().strokeBorder(borderColor, lineWidth: 1)
        }
        .accessibilityLabel("Rotation goal: \(goal.label)")
    }

    private var foregroundColor: Color {
        switch goal {
        case .oneAndDone:
            return DS.Color.textTertiary
        case .sometimes:
            return DS.Color.accentText
        case .staple:
            return DS.Color.panel
        }
    }

    private var backgroundColor: Color {
        switch goal {
        case .oneAndDone:
            return Color.clear
        case .sometimes:
            return DS.Color.accentSoft
        case .staple:
            return DS.Color.accent
        }
    }

    private var borderColor: Color {
        switch goal {
        case .oneAndDone:
            return DS.Color.lineStrong
        case .sometimes:
            return Color.clear
        case .staple:
            return Color.clear
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        RotationPill(goal: .oneAndDone)
        RotationPill(goal: .sometimes)
        RotationPill(goal: .staple)
    }
    .padding()
    .background(DS.Color.bg)
}
