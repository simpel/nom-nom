import SwiftUI

extension View {
    /// Draws a labelled `SwiftUI.Toggle` as the design-system switch (`DSToggleStyle`),
    /// label before the switch. The Toggle README puts a switch only in a ListRow's
    /// trailing slot with no label beside it, so new code uses `AppToggle` there.
    @available(*, deprecated, message: "Use AppToggle in a ListRow trailing slot (.toggle)")
    func nativeToggle() -> some View {
        toggleStyle(DSToggleStyle())
    }
}
