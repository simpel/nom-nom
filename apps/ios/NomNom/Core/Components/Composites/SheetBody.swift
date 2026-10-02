import SwiftUI

/// The scrolling body of a BottomSheet: its blocks (SheetHero, SheetCards, sections)
/// `spacing-6` apart, padded `spacing-2` / `spacing-5` / `spacing-10` (top / sides /
/// bottom) on the `sheet` ground. The bar above it is the navigation bar
/// (`.screenTitle(_:displayMode: .inline)` + `.sheetCloseToolbar()`), and the sheet
/// itself is `.dsSheet(detents:)`.
///
/// ```swift
/// NavigationStack {
///     SheetBody {
///         SheetHero(score: 1, lead: "16 above Joel\u{2019}s usual of 84", emphasis: "16 above")
///         SheetCard("Why Joel loved it", reasons: reasons)
///     }
///     .screenTitle("Joel\u{2019}s score", displayMode: .inline)
///     .sheetCloseToolbar()
/// }
/// .dsSheet(detents: [.medium, .large])
/// ```
struct SheetBody<Content: View>: View {
    @ViewBuilder var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            // bundle.css `.nn-sheet`: gap `spacing-6`, padding `spacing-2` `spacing-5` `spacing-10`.
            VStack(alignment: .leading, spacing: DS.Spacing.s6) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.Spacing.s5)
            .padding(.top, DS.Spacing.s2)
            .padding(.bottom, DS.Spacing.s10)
        }
        .background(DS.Color.sheet)
    }
}
