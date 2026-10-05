import SwiftUI

/// The bottom scrim under text on a photo. README "Imagery": "Text over a photo gets a
/// bottom scrim: `stone-1000` at 72% fading to clear at 32% from the top (5.8:1 over the
/// plate)." 72% is not an opacity step and 32% is not a token (DS-GAPS.md, "core").
struct PhotoScrim: View {
    /// README "Imagery": "`stone-1000` at 72%".
    private static let scrimOpacity = 0.72 // ds-lint:allow README "Imagery": "stone-1000 at 72%"
    /// README "Imagery": "fading to clear at 32% from the top".
    private static let clearStop = 0.32 // ds-lint:allow README "Imagery": "clear at 32% from the top"

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .clear, location: Self.clearStop),
                .init(color: DS.Color.Stone.stone1000.opacity(Self.scrimOpacity), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}
