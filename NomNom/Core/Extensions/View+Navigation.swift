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
}
