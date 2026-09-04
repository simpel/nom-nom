import SwiftUI

extension View {
    /// Applies a standardized screen or sheet title with centralized display mode behavior.
    ///
    /// The title typography is governed by `AppTypography`:
    /// - Expanded page title: 32pt Newsreader Regular (`AppTypography.pageTitleFontName`).
    /// - Compact navbar title: Inter Light 300 (`AppTypography.navBarTitleFontName`).
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
        toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    NotificationBellButton()
                    SettingsDropdownMenu()
                    CreateDropdownMenu()
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
                HStack(spacing: 12) {
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
