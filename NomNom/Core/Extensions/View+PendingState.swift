import SwiftUI

extension View {
    /// Keeps the view's layout footprint and dimensions intact while displaying a centered spinner
    /// when `isLoading` is true.
    ///
    /// Applying this to a button's label preserves the exact intrinsic size, height, and shape of the button,
    /// preventing height jumps or shape collapses during asynchronous operations.
    @ViewBuilder
    func pendingState(_ isLoading: Bool, controlSize: ControlSize? = nil) -> some View {
        self
            .opacity(isLoading ? 0 : 1)
            .overlay {
                if isLoading {
                    if let controlSize {
                        ProgressView()
                            .controlSize(controlSize)
                    } else {
                        ProgressView()
                    }
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isLoading)
    }
}
