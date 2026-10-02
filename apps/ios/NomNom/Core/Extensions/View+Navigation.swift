import SwiftUI

extension View {
    /// Applies a standardized screen or sheet title with centralized display mode behavior.
    ///
    /// The title typography is set globally in `AppDelegate.configureGlobalTypography()`:
    /// - Expanded page title: `DS.TextStyle.serifLg`.
    /// - Compact navbar title: `DS.TextStyle.sansLg` semibold.
    func screenTitle(
        _ title: String,
        displayMode: NavigationBarItem.TitleDisplayMode = .large
    ) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(displayMode)
    }

    /// Standard top-bar trailing toolbar for primary root tabs (Meals, Parties, Recipes).
    /// Houses the shared `SettingsDropdownMenu` alongside the `CreateDropdownMenu`,
    /// ensuring identical icon sizing, font weights, inter-item spacing, and edge insets.
    func mainTabToolbar() -> some View {
        self
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: DS.Spacing.s3) {
                        NotificationBellButton()
                        SettingsDropdownMenu()
                    }
                }
            }
    }

    /// Overload for custom single action button where needed.
    func mainTabToolbar(
        actionAccessibilityLabel: String,
        onAction: @escaping () -> Void
    ) -> some View {
        toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: DS.Spacing.s3) {
                    NotificationBellButton()
                    SettingsDropdownMenu()

                    Button(action: onAction) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel(actionAccessibilityLabel)
                }
            }
        }
    }
}
