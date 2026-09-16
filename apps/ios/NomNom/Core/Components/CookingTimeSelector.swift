import SwiftUI

/// Standalone, tactile cooking time / effort selector.
/// Matches the design system styling and 2-tier typography of the Rate Meal view selectors.
struct CookingTimeSelector: View {
    @Binding var selection: EffortLevel?

    var body: some View {
        HStack(spacing: 6) {
            ForEach(EffortLevel.allCases) { level in
                let isSelected = selection == level

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        selection = isSelected ? nil : level
                    }
                } label: {
                    VStack(spacing: 5) {
                        Text(level.label)
                            .font(.inter(size: 13, weight: isSelected ? .bold : .semibold))
                            .foregroundStyle(isSelected ? DS.Color.accentText : DS.Color.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        if let desc = level.description {
                            Text(desc)
                                .font(.inter(size: 10.5, weight: .regular))
                                .foregroundStyle(isSelected ? DS.Color.textPrimary.opacity(0.85) : DS.Color.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .padding(.horizontal, 4)
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
                .accessibilityLabel("\(level.label), \(level.description ?? "")")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

typealias EffortLevelSelector = CookingTimeSelector

#Preview {
    @Previewable @State var effort: EffortLevel? = .thirtyTo60

    VStack(spacing: 24) {
        CookingTimeSelector(selection: $effort)
    }
    .padding()
    .background(DS.Color.bg)
}
