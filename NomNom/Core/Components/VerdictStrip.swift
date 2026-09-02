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
                            .foregroundStyle(reaction.text)
                    } else {
                        Image(systemName: "circle.dashed")
                            .font(.caption2)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background {
                    if let reaction = entry.reaction {
                        Capsule().fill(reaction.fill.opacity(0.16))
                    } else {
                        Capsule().fill(DS.Color.sunken)
                    }
                }
                .accessibilityLabel(entry.reaction != nil ? "\(entry.name): \(entry.reaction!.name)" : "\(entry.name): Unrated")
            }
        }
    }
}
