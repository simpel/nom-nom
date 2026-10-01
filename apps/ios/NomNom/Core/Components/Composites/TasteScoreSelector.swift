import SwiftUI

/// The six-step taste scale for rating a meal yourself: a centred row of `lg`
/// AppButtons labelled −1…5 with the chosen verdict word underneath.
///
/// Unselected steps are `secondary elevated`; the selected step is its reaction
/// `soft` plus a 1.5pt fill ring. Tap the selected step again to clear it.
/// Six 48pt steps with `s2` gaps take 328pt, so the row fits a 375pt screen
/// inside `s4` gutters.
struct TasteScoreSelector: View {
    @Binding var selection: Reaction?
    var showVerdict: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(selection: Binding<Reaction?>, showVerdict: Bool = true) {
        self._selection = selection
        self.showVerdict = showVerdict
    }

    var body: some View {
        VStack(spacing: DS.Spacing.s3) {
            HStack(spacing: DS.Spacing.s2) {
                ForEach(Reaction.allCases) { reaction in
                    step(reaction)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Taste")

            if showVerdict {
                Text(selection?.name ?? "Not rated yet")
                    .textStyle(.sansSm, tone: selection == nil ? .tertiary : .primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: selection)
    }

    private func step(_ reaction: Reaction) -> some View {
        let isSelected = selection == reaction
        return AppButton(
            icon: .text(Self.glyph(for: reaction)),
            accessibilityLabel: "\(Self.glyph(for: reaction)): \(reaction.name)",
            variant: isSelected ? .reaction(reaction) : .secondary,
            appearance: isSelected ? .soft : .elevated,
            size: .lg
        ) {
            let animation: Animation? = reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.75)
            withAnimation(animation) {
                selection = isSelected ? nil : reaction
            }
        }
        .overlay {
            if isSelected {
                Capsule()
                    .strokeBorder(reaction.fill, lineWidth: DSAppearance.outlineWidth)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "Double-tap to clear" : "")
    }

    /// The step numeral with a true minus ("−1").
    static func glyph(for reaction: Reaction) -> String {
        reaction.numberLabel.replacingOccurrences(of: "-", with: "\u{2212}")
    }
}

private struct TasteScoreSelectorPreview: View {
    @State private var unrated: Reaction?
    @State private var rated: Reaction? = .great

    var body: some View {
        VStack(spacing: DS.Spacing.s8) {
            TasteScoreSelector(selection: $unrated)
            TasteScoreSelector(selection: $rated)
        }
        .padding(DS.Spacing.gutter)
        .frame(width: 375)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { TasteScoreSelectorPreview() }
#Preview("Dark") { TasteScoreSelectorPreview().preferredColorScheme(.dark) }
