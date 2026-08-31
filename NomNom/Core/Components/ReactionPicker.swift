import SwiftUI

/// The three-way verdict picker, one per person.
struct ReactionPicker: View {
    let emoji: String
    let name: String
    @Binding var selection: Reaction?

    var body: some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(.title3)
            Text(name)
                .font(.body)
            Spacer(minLength: 8)
            HStack(spacing: 6) {
                ForEach(Reaction.allCases) { reaction in
                    Button {
                        withAnimation(.snappy(duration: 0.18)) {
                            selection = (selection == reaction) ? nil : reaction
                        }
                    } label: {
                        Text(reaction.emoji)
                            .font(.title3)
                            .frame(width: 40, height: 34)
                            .background {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(selection == reaction ? reaction.tint.opacity(0.22) : Color.clear)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .strokeBorder(selection == reaction ? reaction.tint : Color.secondary.opacity(0.25),
                                                  lineWidth: selection == reaction ? 2 : 1)
                            }
                            .opacity(selection == nil || selection == reaction ? 1 : 0.45)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(name): \(reaction.label)")
                }
            }
        }
    }
}
