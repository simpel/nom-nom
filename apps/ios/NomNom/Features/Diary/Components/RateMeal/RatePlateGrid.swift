import SwiftUI

/// How much of the plate the eater ate: a 2 × 2 grid of square ChoiceTiles, each with
/// its label over a Bar showing the portion ("Had seconds" runs past a full plate).
struct RatePlateGrid: View {
    @Binding var selection: PlateCleared?
    var onPick: (() -> Void)?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.s2), count: 2)

    var body: some View {
        LazyVGrid(columns: columns, spacing: DS.Spacing.s2) {
            ForEach(PlateCleared.allCases) { plate in
                let isSelected = selection == plate
                ChoiceTile(isSelected: isSelected) {
                    selection = plate
                    onPick?()
                } label: {
                    VStack(spacing: DS.Spacing.s3) {
                        ChoiceTileText(title: plate.label, isSelected: isSelected)
                        Bar(value: plate.portion, max: PlateCleared.maxPortion, size: .sm)
                            .padding(.horizontal, DS.Spacing.s6)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityLabel(plate.label)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: selection)
    }
}

#Preview {
    @Previewable @State var plate: PlateCleared? = .cleared

    RatePlateGrid(selection: $plate)
        .padding(DS.Spacing.gutter)
        .background(DS.Color.sheet)
}
