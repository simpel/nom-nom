import SwiftUI

/// The six-step taste scale as a 3 × 2 grid of square ChoiceTiles: the numeral in
/// `serif-md` over the verdict word. The chosen tile takes its reaction colour (tint
/// and ink); colour confirms, the numeral and word carry the meaning.
struct RateTasteGrid: View {
    @Binding var selection: Reaction?
    var onPick: (() -> Void)?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.s2), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: DS.Spacing.s2) {
            ForEach(Reaction.allCases) { reaction in
                let isSelected = selection == reaction
                let glyph = TasteScoreSelector.glyph(for: reaction)
                ChoiceTile(isSelected: isSelected, tint: reaction.fill) {
                    selection = reaction
                    onPick?()
                } label: {
                    ChoiceTileText(title: glyph, subtitle: reaction.name, titleStyle: .serifMd,
                                   numeric: true, isSelected: isSelected, ink: reaction.text)
                }
                .accessibilityLabel("\(glyph): \(reaction.name)")
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: selection)
    }
}

#Preview {
    @Previewable @State var reaction: Reaction? = .great

    RateTasteGrid(selection: $reaction)
        .padding(DS.Spacing.gutter)
        .background(DS.Color.sheet)
}
