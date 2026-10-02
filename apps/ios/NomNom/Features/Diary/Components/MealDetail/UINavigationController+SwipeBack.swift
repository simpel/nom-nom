import UIKit

// Meal Detail hides the navigation bar and draws its own floating back button,
// which turns off UIKit's edge-swipe back. This keeps the gesture working on any
// pushed screen (it only begins when there is something to pop).
// TODO(design-system): move to Core/Extensions once Recipe and Party Detail use
// the floating back button too.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === interactivePopGestureRecognizer else { return true }
        return viewControllers.count > 1
    }
}
