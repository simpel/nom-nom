import SwiftUI

/// Whether the eater wants the meal again: three square ChoiceTiles, the answer in
/// serif over what it means in sans.
struct RateAgainGrid: View {
    @Binding var selection: WantAgain?
    var onPick: (() -> Void)?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.s2), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: DS.Spacing.s2) {
            ForEach(WantAgain.allCases) { again in
                let isSelected = selection == again
                ChoiceTile(isSelected: isSelected) {
                    selection = again
                    onPick?()
                } label: {
                    ChoiceTileText(title: again.label, subtitle: again.description, isSelected: isSelected)
                }
                .accessibilityLabel("\(again.label), \(again.description)")
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: selection)
    }
}

#Preview {
    @Previewable @State var again: WantAgain? = .soon

    RateAgainGrid(selection: $again)
        .padding(DS.Spacing.gutter)
        .background(DS.Color.sheet)
}
