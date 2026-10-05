// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// One square choice in a single-choice grid (the rate-a-meal steps): a `panel` tile at
/// `radius-3xl`, the same surface as Card, with no border and no shadow. Chosen, it
/// takes its `tint` at `opacity-20` over `panel` (README "`opacity-20` selected cells")
/// and the content inks itself from `isSelected`. A reaction step passes its
/// `reaction.fill`; every other choice uses `primary`.
///
/// Toggle-button semantics like TasteScoreSelector: the parent decides what a second
/// tap does. Press is `opacity-70` (AppPressableButtonStyle); the parent plays the
/// light haptic with `.sensoryFeedback` on its selection.
struct ChoiceTile<Label: View>: View {
    let isSelected: Bool
    var tint: Color = DS.Color.primary
    /// Square by default (the rate-a-meal grids); `false` lets a row of tiles keep its height to its copy, with the compact `radius-lg`.
    var square: Bool = true
    let action: () -> Void
    @ViewBuilder var label: Label

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: square ? DS.Radius.xl3 : DS.Radius.lg, style: .continuous)
    }

    @ViewBuilder
    private func sized(_ content: some View) -> some View {
        if square {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
        } else {
            content.frame(maxWidth: .infinity)
        }
    }

    var body: some View {
        Button {
            withAnimation(OptionCell<EmptyView>.selectionAnimation(reduceMotion: reduceMotion)) { action() }
        } label: {
            sized(label.padding(DS.Spacing.s2))
                .background {
                    shape.fill(DS.Color.panel)
                    if isSelected {
                        shape.fill(tint.opacity(DS.Opacity.selected))
                    }
                }
                .contentShape(shape)
        }
        .buttonStyle(AppPressableButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// The tile copy: a serif title over an optional sans line, centred. Chosen, both take
/// `ink` and the sans line goes semibold.
struct ChoiceTileText: View {
    let title: String
    var subtitle: String?
    var titleStyle: DS.TextStyle = .serifXs
    var numeric: Bool = false
    let isSelected: Bool
    var ink: Color = DS.Color.primaryText

    var body: some View {
        VStack(spacing: DS.Spacing.s0_5) {
            Text(title)
                .textStyle(titleStyle, tone: nil, numeric: numeric, lines: 2, align: .center)
                .foregroundStyle(isSelected ? ink : DS.Color.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .textStyle(.sansSm, tone: nil, weight: isSelected ? .semibold : nil, lines: 2, align: .center)
                    .foregroundStyle(isSelected ? ink : DS.Color.textSecondary)
            }
        }
    }
}

private struct ChoiceTilePreview: View {
    @State private var reaction: Reaction? = .great

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.s2), count: 3), spacing: DS.Spacing.s2) {
            ForEach(Reaction.allCases) { r in
                ChoiceTile(isSelected: reaction == r, tint: r.fill) { reaction = r } label: {
                    ChoiceTileText(title: TasteScoreSelector.glyph(for: r), subtitle: r.name,
                                   titleStyle: .serifMd, numeric: true, isSelected: reaction == r, ink: r.text)
                }
            }
        }
        .padding(DS.Spacing.gutter)
        .background(DS.Color.sheet)
    }
}

#Preview("Light") { ChoiceTilePreview() }
#Preview("Dark") { ChoiceTilePreview().preferredColorScheme(.dark) }
