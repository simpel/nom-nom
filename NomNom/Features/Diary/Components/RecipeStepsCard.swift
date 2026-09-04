import SwiftUI

/// Structured step-by-step cooking instructions with connected timeline rail and aligned numbering.
struct RecipeStepsCard: View {
    let instructions: [String]

    private var validSteps: [String] {
        instructions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        if !validSteps.isEmpty {
            SectionCard("Instructions", caption: "\(validSteps.count) steps") {
                VStack(spacing: 0) {
                    ForEach(Array(validSteps.enumerated()), id: \.offset) { index, step in
                        stepRow(step: step, index: index)
                    }
                }
            }
        }
    }

    private func stepRow(step: String, index: Int) -> some View {
        let isLast = index == validSteps.count - 1

        return HStack(alignment: .top, spacing: 14) {
            // Numbered Badge & Vertical Connecting Track
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(DS.Color.accentSoft)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .strokeBorder(DS.Color.accent.opacity(0.3), lineWidth: 0.8)
                        )

                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.Color.accentText)
                }

                if !isLast {
                    Rectangle()
                        .fill(DS.Color.line.opacity(0.35))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .frame(width: 24)

            // Step Instruction Text
            Text(step)
                .font(.subheadline)
                .lineSpacing(4)
                .foregroundStyle(DS.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)
                .padding(.bottom, isLast ? 2 : 18)
                .textSelection(.enabled)
        }
    }
}
