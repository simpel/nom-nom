import SwiftUI

/// Drag to reorder, for any set of views in either direction (components/Reorder/README.md):
/// the rows of a list Card, the tiles of a horizontal strip. The views that share one
/// `dragging` binding form one set, and a view can move between lists in it (a recipe's
/// ingredient groups).
///
/// A drag starts with a long press (the system drag lift), so a pan along either axis
/// still scrolls and a sideways swipe still opens a SwipeRow. While a view is held the
/// others make room live (`duration-layout`) and its own slot stays at
/// `opacity-disabled`. Dropping on a view takes its place; on a `reorderDropTarget`
/// (a list's footer, an empty list), whatever that target does. Every view also gets
/// "Move up / Move down" (`.vertical`) or "Move left / Move right" (`.horizontal`)
/// accessibility actions.
///
/// ```swift
/// ForEach(items) { item in
///     ListRow(item.name, leading: .icon("line.3.horizontal"))
///         .reorderable(item.id, dragging: $dragging, axis: .vertical,
///                      previous: before(item), next: after(item)) { moved, target in
///             items.move(moved, toPlaceOf: target)
///         }
/// }
/// ```
enum ReorderAxis {
    case vertical, horizontal

    var previousLabel: String { self == .vertical ? "Move up" : "Move left" }
    var nextLabel: String { self == .vertical ? "Move down" : "Move right" }
}

extension View {
    /// Makes this view a draggable item of a reorderable set and the drop target that
    /// takes its place. `onMove(moved, target)` puts `moved` where `target` is.
    /// `previous` / `next` are the neighbours the accessibility actions move it past.
    func reorderable<ID: Hashable>(
        _ id: ID,
        dragging: Binding<ID?>,
        axis: ReorderAxis,
        previous: ID? = nil,
        next: ID? = nil,
        onMove: @escaping (ID, ID) -> Void
    ) -> some View {
        opacity(dragging.wrappedValue == id ? DS.Opacity.disabled : 1)
            .onDrag {
                dragging.wrappedValue = id
                return ReorderItemProvider(String(describing: id)) {
                    if dragging.wrappedValue == id { dragging.wrappedValue = nil }
                }
            }
            .onDrop(of: [.text], delegate: ReorderDropDelegate(dragging: dragging) { moved in
                if moved != id { onMove(moved, id) }
            })
            .accessibilityAction(named: axis.previousLabel) { if let previous { onMove(id, previous) } }
            .accessibilityAction(named: axis.nextLabel) { if let next { onMove(id, next) } }
    }

    /// A drop target with no item of its own: the end of a list, an empty list.
    /// `onEnter(moved)` runs as a dragged item comes over it.
    func reorderDropTarget<ID: Hashable>(dragging: Binding<ID?>, onEnter: @escaping (ID) -> Void) -> some View {
        onDrop(of: [.text], delegate: ReorderDropDelegate(dragging: dragging, onEnter: onEnter))
    }
}
