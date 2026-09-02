import SwiftUI

/// A clean, tactile taste reaction selector (-1 to 5) for household eaters rows.
struct TactileTasteSelector: View {
    @Binding var selection: Reaction?

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Reaction.allCases) { reaction in
                let isSelected = selection == reaction
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        selection = isSelected ? nil : reaction
                    }
                } label: {
                    Text(reaction.numberLabel)
                        .font(.system(size: 11, weight: isSelected ? .bold : .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? reaction.tint : .secondary)
                        .frame(minWidth: 26, minHeight: 26)
                        .background {
                            RoundedRectangle(cornerRadius: AppRadius.picker, style: .continuous)
                                .fill(isSelected ? reaction.tint.opacity(0.18) : Color(uiColor: .tertiarySystemFill))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.picker, style: .continuous)
                                .strokeBorder(isSelected ? reaction.tint : Color.clear, lineWidth: 1.5)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(reaction.numberLabel): \(reaction.name)")
            }
        }
    }
}
