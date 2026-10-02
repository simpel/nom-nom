import SwiftUI

/// The six-step taste scale for rating a meal yourself: a centred row of `lg`
/// AppButtons labelled −1…5 (`spacing-12` circles, `sans-lg` semibold tabular
/// numerals, `spacing-2` apart) with the chosen verdict word underneath, `spacing-2`
/// below (bundle.css `.nn-taste`).
///
/// Unselected steps are `secondary elevated`; the selected step is its reaction
/// `soft` plus a fill ring. The steps are toggle buttons, not radios: tapping the
/// chosen step clears the rating. Disable with `.disabled(_:)`.
struct TasteScoreSelector: View {
    @Binding var selection: Reaction?
    /// The group's accessible name.
    var label: String
    var showVerdict: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(selection: Binding<Reaction?>, label: String = "Taste", showVerdict: Bool = true) {
        self._selection = selection
        self.label = label
        self.showVerdict = showVerdict
    }

    var body: some View {
        VStack(spacing: DS.Spacing.s2) {
            HStack(spacing: DS.Spacing.s2) {
                ForEach(Reaction.allCases) { reaction in
                    step(reaction)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(label)

            if showVerdict {
                // README: "one Text `sans-sm`, centred, the same size and weight in both states".
                Text(selection?.name ?? "Not rated yet")
                    .textStyle(.sansSm, tone: selection == nil ? .tertiary : .primary, align: .center)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: selection)
    }

    private func step(_ reaction: Reaction) -> some View {
        let isSelected = selection == reaction
        let glyph = Self.glyph(for: reaction)
        return Button {
            // README: "Spring 0.25 / 0.75." No motion token is a spring (DS-GAPS.md).
            let animation: Animation? = reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.75)
            withAnimation(animation) {
                selection = isSelected ? nil : reaction
            }
        } label: {
            // bundle.css `.nn-taste__row > .nn-button`: width `spacing-12`, padding 0, the
            // `lg` height, so each step is a `spacing-12` circle.
            AppButtonLabel(
                title: nil,
                icon: .text(glyph),
                iconPosition: .start,
                variant: isSelected ? .reaction(reaction) : .secondary,
                appearance: isSelected ? .soft : .elevated,
                size: .lg,
                fullWidth: false,
                isLoading: false,
                accessibilityLabel: "\(glyph): \(reaction.name)",
                iconOnlyDiameter: DS.Spacing.s12
            )
            .overlay {
                if isSelected {
                    // README: "a 1.5px fill ring". No 1.5px width exists; `border-thick`
                    // is the token for a "selected ring" (DS-GAPS.md).
                    Circle()
                        .strokeBorder(reaction.fill, lineWidth: DS.BorderWidth.thick)
                        .allowsHitTesting(false)
                }
            }
        }
        .buttonStyle(AppPressableButtonStyle())
        // Toggle buttons (README "Toggle buttons, not radios"): aria-pressed ≈ isSelected.
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
        .background(DS.Color.bg)
    }
}

#Preview("Light") { TasteScoreSelectorPreview() }
#Preview("Dark") { TasteScoreSelectorPreview().preferredColorScheme(.dark) }
