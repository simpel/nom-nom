import SwiftUI
import UniformTypeIdentifiers

/// Reorder's drop target. The item moves the moment the finger enters a target, so the
/// set shows where it will land; the drop itself only ends the drag.
struct ReorderDropDelegate<ID: Hashable>: DropDelegate {
    @Binding var dragging: ID?
    let onEnter: (ID) -> Void

    func validateDrop(info: DropInfo) -> Bool { dragging != nil }

    func dropEntered(info: DropInfo) {
        guard let dragging else { return }
        withAnimation(DS.Motion.layout) { onEnter(dragging) }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        return true
    }
}

/// The dragged item's provider. SwiftUI reports no drag end, and a drop back on the
/// item's own slot (or outside any target) calls no `performDrop`; the system releases
/// the provider when the session ends, so its release ends the drag.
final class ReorderItemProvider: NSItemProvider {
    private let onEnd: () -> Void

    init(_ text: String, onEnd: @escaping () -> Void) {
        self.onEnd = onEnd
        super.init(item: text as NSString, typeIdentifier: UTType.plainText.identifier)
    }

    deinit {
        let onEnd = onEnd
        DispatchQueue.main.async(execute: onEnd)
    }
}
