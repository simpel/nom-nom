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

    /// Standard top bar for the root tabs (Meals, Parties, Recipes): no title (the body
    /// carries the PageHeader / DetailHeader) and the `PageMenu` on the trailing side.
    /// `addAccessibilityLabel` + `onAdd` put an icon-only "+" before the menu (Recipes).
    func mainTabToolbar(
        addAccessibilityLabel: String? = nil,
        onAdd: (() -> Void)? = nil
    ) -> some View {
        self
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let onAdd {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: onAdd) {
                            Image(systemName: "plus")
                                .fontWeight(DS.TextStyle.Weight.semibold.fontWeight)
                        }
                        .accessibilityLabel(addAccessibilityLabel ?? "Add")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    PageMenu()
                }
            }
    }
}
