import SwiftUI
import UIKit

/// Reports a swipe-to-dismiss that `interactiveDismissDisabled` refused, so a changed
/// edit sheet can ask "Discard changes?" the way Mail does. Put it in the sheet's
/// background (`.editorSheet` does).
///
/// SwiftUI sheets are backed by a `UIPresentationController` whose delegate is SwiftUI's
/// own. This wraps that delegate in a proxy that forwards every call to it and also
/// reports `presentationControllerDidAttemptToDismiss`. Apple doesn't document the
/// backing controller as API: if it ever changes, a changed sheet still can't be swiped
/// away (SwiftUI keeps refusing), it just won't show the prompt.
struct SheetDismissAttemptObserver: UIViewRepresentable {
    let onAttempt: () -> Void

    func makeUIView(context: Context) -> ObserverView {
        ObserverView()
    }

    func updateUIView(_ view: ObserverView, context: Context) {
        view.onAttempt = onAttempt
        view.install()
    }

    final class ObserverView: UIView {
        var onAttempt: (() -> Void)?
        private var proxy: DelegateProxy?

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            isHidden = true
        }

        required init?(coder: NSCoder) { nil }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            // The hosting controller is attached to its parent after the view joins the window.
            DispatchQueue.main.async { [weak self] in self?.install() }
        }

        /// Wraps the sheet's presentation-controller delegate, again if SwiftUI replaced it.
        func install() {
            guard let controller = presentedController()?.presentationController else { return }
            if let proxy, controller.delegate === proxy { return }
            let proxy = DelegateProxy(wrapping: controller.delegate) { [weak self] in self?.onAttempt?() }
            self.proxy = proxy
            controller.delegate = proxy
        }

        /// The view controller the sheet presents: the topmost parent of this view's controller.
        private func presentedController() -> UIViewController? {
            var responder: UIResponder? = self
            while let next = responder?.next, !(next is UIViewController) { responder = next }
            var controller = responder?.next as? UIViewController
            while let parent = controller?.parent { controller = parent }
            return controller
        }
    }

    /// Forwards every delegate call to SwiftUI's delegate (held strongly: the
    /// presentation controller only holds its delegate weakly) and reports refused swipes.
    final class DelegateProxy: NSObject, UIAdaptivePresentationControllerDelegate {
        private let original: UIAdaptivePresentationControllerDelegate?
        private let onAttempt: () -> Void

        init(wrapping original: UIAdaptivePresentationControllerDelegate?, onAttempt: @escaping () -> Void) {
            self.original = original
            self.onAttempt = onAttempt
        }

        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
            original?.presentationControllerDidAttemptToDismiss?(presentationController)
            onAttempt()
        }

        override func responds(to selector: Selector!) -> Bool {
            super.responds(to: selector) || (original?.responds(to: selector) ?? false)
        }

        override func forwardingTarget(for selector: Selector!) -> Any? {
            original?.responds(to: selector) == true ? original : super.forwardingTarget(for: selector)
        }
    }
}
