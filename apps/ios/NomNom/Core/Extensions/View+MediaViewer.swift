import SwiftUI

extension View {
    /// Applies consistent styling, dark theme, and navigation bar appearance for full-screen photo/media viewers.
    func mediaViewerStyle(onClose: (() -> Void)? = nil) -> some View {
        self
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.85), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheetCloseToolbar(color: .white, onClose: onClose)
            .preferredColorScheme(.dark)
    }
}
