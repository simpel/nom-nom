import SwiftUI

/// Compact read-only row of member verdicts on a meal.
struct VerdictStrip: View {
    let entries: [(emoji: String, name: String, reaction: Reaction?)]
    var showNames: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(entries.enumerated()), id: \.offset) { indexed in
                let entry = indexed.element
                HStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 18, height: 18)
                        Text(entry.name.prefix(1).uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.accentColor)
                    }

                    if showNames {
                        Text(entry.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let reaction = entry.reaction {
                        Text(reaction.numberLabel)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(reaction.tint)
                    } else {
                        Text("–")
                            .font(.caption2)
                            .foregroundStyle(.secondary.opacity(0.4))
                    }
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background {
                    Capsule().fill((entry.reaction?.tint ?? .gray).opacity(entry.reaction == nil ? 0.08 : 0.16))
                }
            }
        }
    }
}
