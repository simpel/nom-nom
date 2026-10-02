import SwiftUI

/// Numbered cooking steps on a vertical rail, in a SectionCard.
struct RecipeStepsCard: View {
    let instructions: [String]

    private static let numberSize = DS.Spacing.s6

    private var validSteps: [String] {
        instructions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        if !validSteps.isEmpty {
            SectionCard("Instructions", trailing: "\(validSteps.count) steps") {
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

        return HStack(alignment: .top, spacing: DS.Spacing.s3) {
            VStack(spacing: 0) {
                Text("\(index + 1)")
                    .textStyle(.sansXs, tone: .accent, weight: .semibold, numeric: true)
                    .frame(width: Self.numberSize, height: Self.numberSize)
                    .background(DS.Color.primarySoft, in: Circle())
                    .accessibilityLabel("Step \(index + 1)")

                if !isLast {
                    Rectangle()
                        .fill(DS.Color.line)
                        .frame(width: DS.Spacing.s0_5)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, DS.Spacing.s1)
                        .accessibilityHidden(true)
                }
            }
            .frame(width: Self.numberSize)

            Text(step)
                .textStyle(.sansMd)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, DS.Spacing.s0_5)
                .padding(.bottom, isLast ? DS.Spacing.s0_5 : DS.Spacing.s4)
                .textSelection(.enabled)
        }
    }
}
