import SwiftUI

extension View {
    /// Applies native iOS switch styling with standard Apple system green on-tint.
    /// Ensures consistent, native toggle appearance across all screens and sheets,
    /// preventing accidental tint overrides from custom brand AccentColors.
    func nativeToggle() -> some View {
        self
            .toggleStyle(.switch)
            .tint(Color(uiColor: .systemGreen))
    }
}
