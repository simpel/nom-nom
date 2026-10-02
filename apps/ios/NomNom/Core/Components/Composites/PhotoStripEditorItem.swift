// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import Foundation

/// One photo in a PhotoStripEditor: a stable id (for animation) and its PhotoCard source.
struct PhotoStripEditorItem: Identifiable {
    let id: String
    let source: PhotoCardSource
}

/// What PhotoStripEditor marks on each tile.
enum PhotoStripEditorBadge: Equatable {
    /// "Cover" on the first photo (cover photo sets).
    case cover
    /// "Page 1", "Page 2"… (recipe pages, scanned pages).
    case pageNumber
    case none

    func text(at index: Int) -> String? {
        switch self {
        case .cover: return index == 0 ? "Cover" : nil
        case .pageNumber: return "Page \(index + 1)"
        case .none: return nil
        }
    }
}
