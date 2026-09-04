import SwiftUI

/// Standalone, tactile rotation goal selector for rating meals.
/// Designed to sit directly on the background surface with clear 2-tier typography
/// and unambiguous active selection state.
struct RotationGoalSelector: View {
    @Binding var selection: RotationGoal?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(RotationGoal.allCases) { goal in
                let isSelected = selection == goal

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        selection = isSelected ? nil : goal
                    }
                } label: {
                    VStack(spacing: 5) {
                        Text(goal.label)
                            .font(.inter(size: 13, weight: isSelected ? .bold : .semibold))
                            .foregroundStyle(isSelected ? DS.Color.accentText : DS.Color.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        if let desc = goal.description {
                            Text(desc)
                                .font(.inter(size: 10.5, weight: .regular))
                                .foregroundStyle(isSelected ? DS.Color.textPrimary.opacity(0.85) : DS.Color.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .padding(.horizontal, 6)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                            .fill(isSelected ? DS.Color.accentSoft.opacity(0.40) : DS.Color.panel)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                            .strokeBorder(
                                isSelected ? DS.Color.accent : DS.Color.line.opacity(0.8),
                                lineWidth: isSelected ? 1.5 : 0.6
                            )
                    }
                    .shadow(
                        color: isSelected ? DS.Color.accent.opacity(0.10) : Color.black.opacity(0.04),
                        radius: isSelected ? 4 : 3,
                        x: 0,
                        y: 1.5
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(goal.label), \(goal.description ?? "")")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

#Preview {
    @Previewable @State var goal: RotationGoal? = .staple

    VStack(spacing: 24) {
        RotationGoalSelector(selection: $goal)
    }
    .padding()
    .background(DS.Color.bg)
}
