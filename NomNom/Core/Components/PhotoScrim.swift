import SwiftUI

/// Gradient scrim for text overlaid on photography to guarantee minimum 5.8:1 contrast:
/// `rgba(6,8,12,0.72)` (stone1000 @ 0.72) at bottom fading to transparent at 68% height.
struct PhotoScrim: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.0),
                .init(color: .clear, location: 0.32),
                .init(color: DS.Color.Stone.stone1000.opacity(0.72), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}

extension View {
    /// Applies a standard photo bottom scrim gradient.
    func photoBottomScrim() -> some View {
        overlay(alignment: .bottom) {
            PhotoScrim()
        }
    }
}
