import SwiftUI

extension View {
    /// Dark chrome for full-screen photo/media viewers: a `stone-1000` ground (README
    /// "Imagery"'s scrim colour, the darkest ramp step) under a `stone-1000` navigation bar
    /// at `opacity-90`, the dark colour scheme and the leading close.
    func mediaViewerStyle(onClose: (() -> Void)? = nil) -> some View {
        self
            .background(DS.Color.Stone.stone1000.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(DS.Color.Stone.stone1000.opacity(DS.Opacity.o90), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheetCloseToolbar(onClose: onClose)
            .preferredColorScheme(.dark)
    }
}
