import SwiftUI

/// One selectable picker cell, shared by the "not synced" selectors (CookingTimeSelector,
/// RotationGoalSelector, TactileTasteSelector).
///
/// README "Layout, radius, elevation": "`radius-lg` for compact score boxes and picker
/// cells", "`opacity-20` selected cells"; "Every control boundary clears 3:1 … use
/// `line-control`". So a cell is a `panel` ground with a `border-hairline` `line-control`
/// ring at rest, and its `tint` at `opacity-20` with a `border-thick` `tint` ring
/// ("selected ring") when chosen. Cells don't float, so they carry no shadow.
///
/// README "Motion and states": "Selection springs (≈0.25s) with a light haptic." Tapping
/// the chosen cell clears it (toggle buttons, as TasteScoreSelector). The selector that
/// owns the cells plays the haptic (`.sensoryFeedback` on its selection).
struct OptionCell<Label: View>: View {
    let isSelected: Bool
    var tint: Color = DS.Color.primary
    /// A token from the caller (`DS.Spacing.*`); a minimum, so the cell grows with Dynamic Type.
    var minHeight: CGFloat = DS.Spacing.s11
    let action: () -> Void
    @ViewBuilder var label: Label

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
    }

    var body: some View {
        Button {
            withAnimation(Self.selectionAnimation(reduceMotion: reduceMotion)) { action() }
        } label: {
            label
                .frame(maxWidth: .infinity, minHeight: minHeight)
                .padding(.horizontal, DS.Spacing.s1)
                .background {
                    shape.fill(DS.Color.panel)
                    if isSelected {
                        shape.fill(tint.opacity(DS.Opacity.selected))
                    }
                }
                .overlay {
                    shape.strokeBorder(
                        isSelected ? tint : DS.Color.lineControl,
                        lineWidth: isSelected ? DS.BorderWidth.thick : DS.BorderWidth.hairline
                    )
                }
                .contentShape(shape)
        }
        .buttonStyle(AppPressableButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// "Selection springs (≈0.25s)": a spring over `duration-layout` (250ms). Reduce
    /// Motion drops it.
    static func selectionAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(duration: DS.Motion.durationLayout)
    }
}

/// The two-tier cell copy: the option in `sans-sm` semibold (`primary-text` when chosen)
/// over its description in `sans-xs` `text-secondary`, `spacing-1` apart, centred.
struct OptionCellText: View {
    let label: String
    var description: String?
    let isSelected: Bool

    var body: some View {
        VStack(spacing: DS.Spacing.s1) {
            if !label.isEmpty {
                Text(label)
                    .textStyle(.sansSm, tone: isSelected ? .accent : .primary, weight: .semibold, lines: 1, align: .center)
            }
            if let description {
                Text(description)
                    .textStyle(.sansXs, tone: .secondary, lines: 2, align: .center)
            }
        }
        .padding(.vertical, DS.Spacing.s2)
    }
}
