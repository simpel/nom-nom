import SwiftUI

/// Standalone, tactile taste reaction selector (-1 to 5) for rating meals.
/// Designed to sit directly on the background surface without redundant card containers.
struct TasteScoreSelector: View {
    @Binding var selection: Reaction?

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Reaction.allCases) { reaction in
                let isSelected = selection == reaction

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        selection = isSelected ? nil : reaction
                    }
                } label: {
                    Text(reaction.numberLabel)
                        .font(.system(size: 18, weight: isSelected ? .bold : .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? reaction.text : DS.Color.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background {
                            RoundedRectangle(cornerRadius: AppRadius.picker, style: .continuous)
                                .fill(isSelected ? reaction.fill.opacity(0.20) : DS.Color.panel)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.picker, style: .continuous)
                                .strokeBorder(
                                    isSelected ? reaction.fill : DS.Color.line.opacity(0.8),
                                    lineWidth: isSelected ? 1.5 : 0.6
                                )
                        }
                        .shadow(
                            color: isSelected ? reaction.fill.opacity(0.14) : Color.black.opacity(0.04),
                            radius: isSelected ? 4 : 3,
                            x: 0,
                            y: 1.5
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(reaction.numberLabel): \(reaction.name)")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

#Preview {
    @Previewable @State var reaction: Reaction? = .good

    VStack(spacing: 24) {
        TasteScoreSelector(selection: $reaction)
    }
    .padding()
    .background(DS.Color.bg)
}
