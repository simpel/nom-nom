import SwiftUI

/// Section in recipe editors for adding, modifying, and removing numbered preparation steps.
struct RecipeInstructionsEditorSection: View {
    @Binding var instructions: [String]
    @State private var openRowID: Int?

    var body: some View {
        DSSection("Instructions") {
            Card(layout: .list) {
                ForEach(Array(instructions.indices), id: \.self) { index in
                    SwipeActionRow(
                        id: index,
                        openRowID: $openRowID,
                        trailingIcon: "trash",
                        trailingColor: DS.Color.destructive,
                        onTrailingAction: {
                            removeStep(at: index)
                        }
                    ) {
                        stepRow(at: index)
                    }
                }

                AppButton("Add Step", icon: "plus", appearance: .ghost, size: .sm) {
                    withAnimation(DS.Motion.layout) {
                        $instructions.wrappedValue.append("")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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

            NoteField("Describe this step", text: $instructions[index], title: "Step \(index + 1)", onRemove: {
                removeStep(at: index)
            })
        }
    }

    private func removeStep(at index: Int) {
        guard instructions.indices.contains(index) else { return }
        openRowID = nil
        withAnimation(DS.Motion.layout) {
            $instructions.wrappedValue.remove(at: index)
        }
    }
}
