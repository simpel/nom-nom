import SwiftUI

extension View {
    /// A whole Pro-only screen or sheet (`design-system/components/Pro/README.md`, ProView):
    /// the ground is `pro-soft`, the ProMark goes above the title, and the cards on it stay
    /// plain `panel` Cards, with no mark of their own. Apply to the scroll view; for a
    /// sheet's ground pass `pro: true` to `.dsSheet()`.
    func proView() -> some View {
        background(DS.Color.proSoft)
    }
}
