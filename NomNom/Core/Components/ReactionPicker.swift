import SwiftUI

/// Compact verdict selector (-1 to 5) for member rows.
struct ReactionPicker: View {
    let emoji: String
    let name: String
    @Binding var selection: Reaction?

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 30, height: 30)
                Text(name.prefix(1).uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }

            Text(name)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)

            Spacer(minLength: 4)

            HStack(spacing: 4) {
                ForEach(Reaction.allCases) { reaction in
                    let isSelected = selection == reaction
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.snappy(duration: 0.18)) {
                            selection = isSelected ? nil : reaction
                        }
                    } label: {
                        Text(reaction.numberLabel)
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                            .foregroundStyle(isSelected ? reaction.tint : .secondary)
                            .frame(width: 28, height: 28)
                            .background {
                                RoundedRectangle(cornerRadius: AppRadius.picker, style: .continuous)
                                    .fill(isSelected ? reaction.tint.opacity(0.2) : Color(uiColor: .tertiarySystemFill))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: AppRadius.picker, style: .continuous)
                                    .strokeBorder(isSelected ? reaction.tint : Color.clear, lineWidth: 1.5)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(name): \(reaction.numberLabel) - \(reaction.name)")
                }
            }
        }
    }
}
