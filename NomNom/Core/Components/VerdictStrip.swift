import SwiftUI

/// Compact read-only row of member verdicts on a meal.
struct VerdictStrip: View {
    let entries: [(emoji: String, name: String, reaction: Reaction?)]
    var showNames: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(entries.enumerated()), id: \.offset) { indexed in
                let entry = indexed.element
                HStack(spacing: 3) {
                    Text(entry.emoji)
                    if showNames {
                        Text(entry.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(entry.reaction?.emoji ?? "–")
                        .opacity(entry.reaction == nil ? 0.4 : 1)
                }
                .font(.callout)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background {
                    Capsule().fill((entry.reaction?.tint ?? .gray).opacity(entry.reaction == nil ? 0.08 : 0.16))
                }
            }
        }
    }
}
