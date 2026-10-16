import SwiftUI
import UIKit

/// SwipeActionRow's drag. From iOS 18 it is a UIKit pan that only begins when the finger
/// moves more sideways than up or down, so a vertical drag that starts on a row scrolls
/// the list: a SwiftUI DragGesture on a row, even a simultaneous one, holds the touch
/// and the ScrollView never moves. iOS 17 keeps the simultaneous DragGesture.
struct SwipeDragGesture: ViewModifier {
    var isEnabled: Bool
    /// (translation, whether the axis is already known to be horizontal)
    let onChanged: (CGSize, Bool) -> Void
    let onEnded: () -> Void

    /// Drag distance before the row starts to follow the finger (`spacing-4`).
    private let dragThreshold = DS.Spacing.s4

    func body(content: Content) -> some View {
        if !isEnabled {
            content
        } else if #available(iOS 18.0, *) {
            content.gesture(HorizontalPanGesture(onChanged: { onChanged($0, true) }, onEnded: onEnded))
        } else {
            content.simultaneousGesture(
                DragGesture(minimumDistance: dragThreshold)
                    .onChanged { onChanged($0.translation, false) }
                    .onEnded { _ in onEnded() }
            )
        }
    }
}

/// A pan that begins only on a mostly horizontal movement and never shares the touch.
@available(iOS 18.0, *)
private struct HorizontalPanGesture: UIGestureRecognizerRepresentable {
    let onChanged: (CGSize) -> Void
    let onEnded: () -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        switch recognizer.state {
        case .changed:
            let t = recognizer.translation(in: recognizer.view)
            onChanged(CGSize(width: t.x, height: t.y))
        case .ended, .cancelled, .failed:
            onEnded()
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }
    }
}
