import SwiftUI

/// Section in recipe editors for adding, modifying, and removing numbered preparation steps.
struct RecipeInstructionsEditorSection: View {
    @Binding var instructions: [String]

    var body: some View {
        SectionCard("Instructions") {
            VStack(spacing: 10) {
                ForEach(Array(instructions.indices), id: \.self) { index in
                    stepRow(at: index)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        $instructions.wrappedValue.append("")
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.subheadline.weight(.semibold))
                        Text("Add Step")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(DS.Color.accentText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, instructions.isEmpty ? 2 : 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func stepRow(at index: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(index + 1)")
                .font(.caption.weight(.bold))
                .foregroundStyle(DS.Color.textSecondary)
                .frame(width: 24, height: 24)
                .background(DS.Color.sunken, in: Circle())
                .padding(.top, 6)

            TextArea(
                "Step description...",
                text: $instructions[index],
                lineLimit: 2...8,
                font: .subheadline
            )

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    removeStep(at: index)
                }
            } label: {
                Image(systemName: "minus.circle")
                    .font(.body)
                    .foregroundStyle(DS.Color.textTertiary)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
    }

    private func removeStep(at index: Int) {
        guard instructions.indices.contains(index) else { return }
        $instructions.wrappedValue.remove(at: index)
    }
}
