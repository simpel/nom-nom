// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// One tile of a PhotoStripEditor: a PhotoCard `sm` (tap to view), an elevated
/// icon-only remove button top-right and an optional elevated Badge ("Cover",
/// "Page 2") bottom-right. Reordering lives in the tile's context menu and its
/// accessibility actions: Make cover, Move left, Move right.
struct PhotoStripEditorTile: View {
    let item: PhotoStripEditorItem
    let index: Int
    let count: Int
    var badgeText: String?
    var showsMakeCover: Bool
    var onSelect: () -> Void
    var onRemove: () -> Void
    /// Moves this tile to an index; nil when the photos can't be reordered.
    var onMove: ((Int) -> Void)?

    private var canMoveLeft: Bool { onMove != nil && index > 0 }
    private var canMoveRight: Bool { onMove != nil && index < count - 1 }

    var body: some View {
        Button(action: onSelect) {
            PhotoCard(
                item.source,
                size: .sm,
                badge: badgeText.map { .custom(Badge($0, variant: .secondary, appearance: .elevated, size: .sm)) },
                accessibilityLabel: "Photo \(index + 1) of \(count)"
            )
        }
        .buttonStyle(AppPressableButtonStyle())
        .overlay(alignment: .topTrailing) {
            AppButton(
                icon: "xmark",
                accessibilityLabel: "Remove photo \(index + 1)",
                variant: .secondary,
                appearance: .elevated,
                size: .sm,
                action: onRemove
            )
            .padding(DS.Spacing.s2)
        }
        .contextMenu { menu }
        .accessibilityAction(named: "Make cover") { if showsMakeCover, index > 0 { onMove?(0) } }
        .accessibilityAction(named: "Move left") { if canMoveLeft { onMove?(index - 1) } }
        .accessibilityAction(named: "Move right") { if canMoveRight { onMove?(index + 1) } }
    }

    @ViewBuilder
    private var menu: some View {
        if showsMakeCover, canMoveLeft {
            Button("Make cover", systemImage: "star") { onMove?(0) }
        }
        if canMoveLeft {
            Button("Move left", systemImage: "arrow.left") { onMove?(index - 1) }
        }
        if canMoveRight {
            Button("Move right", systemImage: "arrow.right") { onMove?(index + 1) }
        }
        Button("Remove", systemImage: "trash", role: .destructive, action: onRemove)
    }
}
