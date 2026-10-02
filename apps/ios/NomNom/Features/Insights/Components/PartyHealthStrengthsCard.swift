import SwiftUI

/// The nutritional patterns behind a set of meals: a SectionCard each for the top
/// strengths and the watch-outs, one `sans-md` line per item. Draws nothing when both
/// lists are empty.
struct PartyHealthStrengthsCard: View {
    let topStrengths: [String]
    let topConsiderations: [String]

    var body: some View {
        if !topStrengths.isEmpty || !topConsiderations.isEmpty {
            VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                if !topStrengths.isEmpty {
                    list("Strengths", items: topStrengths)
                }
                if !topConsiderations.isEmpty {
                    list("Watch-outs", items: topConsiderations)
                }
            }
        }
    }

    private func list(_ title: String, items: [String]) -> some View {
        SectionCard(title) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .textStyle(.sansMd)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    PartyHealthStrengthsCard(
        topStrengths: ["Plenty of vegetables", "Lean proteins"],
        topConsiderations: ["High sodium on pizza nights"]
    )
    .padding(DS.Spacing.gutter)
    .background(DS.Color.bg)
}
