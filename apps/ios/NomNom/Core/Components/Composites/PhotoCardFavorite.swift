import SwiftUI

/// PhotoCard's favourite heart (components/PhotoCard/README.md, "The favourite heart"):
/// AppButton `secondary elevated` icon-only, 44 × 44 at every tile size. Outlined
/// (`heart`) when not a favourite; filled (`heart.fill`) in `destructive-text` when it
/// is. Fill is the state: the button, its ground and its position never change.
///
/// With `onToggle` it is a toggle ("Add to favourites" / "Remove from favourites");
/// without it, a read-only marker drawn with the same visuals and hidden from
/// accessibility (the tile's own label says "Favourite").
struct PhotoCardFavorite: View {
    let isFavorite: Bool
    var onToggle: (() -> Void)?

    private var symbol: AppButtonIcon { .system(isFavorite ? "heart.fill" : "heart") }
    private var ink: Color? { isFavorite ? DS.Color.destructiveText : nil }

    var body: some View {
        if let onToggle {
            AppButton(
                icon: symbol,
                accessibilityLabel: isFavorite ? "Remove from favourites" : "Add to favourites",
                variant: .secondary,
                appearance: .elevated,
                iconColor: ink,
                action: onToggle
            )
            // README: "`aria-pressed` carries the state, so it is a toggle to a screen reader".
            .accessibilityAddTraits(isFavorite ? [.isToggle, .isSelected] : .isToggle)
        } else {
            AppButtonLabel(
                icon: symbol,
                accessibilityLabel: "Favourite",
                variant: .secondary,
                appearance: .elevated,
                iconColor: ink
            )
            .accessibilityHidden(true)
        }
    }
}
