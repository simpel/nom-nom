import SwiftUI

/// Section in recipe editors for adding, modifying, and removing numbered preparation steps.
struct RecipeInstructionsEditorSection: View {
    @Binding var instructions: [String]

    var body: some View {
        SectionCard("Instructions") {
            VStack(spacing: DS.Spacing.s2_5) {
                ForEach(Array(instructions.indices), id: \.self) { index in
                    stepRow(at: index)
                }

                AppButton("Add Step", icon: "plus", appearance: .ghost, size: .sm) {
                    withAnimation(DS.Motion.layout) {
                        $instructions.wrappedValue.append("")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, instructions.isEmpty ? DS.Spacing.s0_5 : DS.Spacing.s1)
            }
        }
    }

    private func stepRow(at index: Int) -> some View {
        HStack(alignment: .center, spacing: DS.Spacing.s2) {
            Text("\(index + 1)")
                .textStyle(.sansXs, tone: .secondary, weight: .semibold, numeric: true)
                .frame(width: DS.Spacing.s6, height: DS.Spacing.s6)
                .background(DS.Color.sunken, in: Circle())
                .accessibilityLabel("Step \(index + 1)")

            NoteField("Describe this step", text: $instructions[index], title: "Step \(index + 1)")

            AppButton(
                icon: "minus.circle",
                accessibilityLabel: "Remove step",
                variant: .destructive,
                appearance: .ghost
            ) {
                withAnimation(DS.Motion.layout) {
                    removeStep(at: index)
                }
            }
        }
    }

    private func removeStep(at index: Int) {
        guard instructions.indices.contains(index) else { return }
        $instructions.wrappedValue.remove(at: index)
    }
}
