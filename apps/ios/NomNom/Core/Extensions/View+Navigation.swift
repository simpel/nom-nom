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

    /// Standard top bar for the root tabs (Meals, Parties, Recipes): no title and no party
    /// name (the body's ScreenHeader names the party), the `PageMenu` on the trailing side.
    func mainTabToolbar() -> some View {
        mainTabToolbar { EmptyView() }
    }

    /// `mainTabToolbar()` with the tab's own actions as the PageMenu's first group
    /// (Recipes: "New recipe").
    func mainTabToolbar<Context: View>(@ViewBuilder menu: @escaping () -> Context) -> some View {
        self
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PageMenu(context: menu)
                }
            }
    }
}

/// The current dinner party's name, left aligned in the top bar of every root tab.
struct PartyNameToolbarItem: ToolbarContent {
    var body: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: .topBarLeading) { PartyNameLabel() }
                .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarLeading) { PartyNameLabel() }
        }
    }
}

private struct PartyNameLabel: View {
    @Environment(FoodStore.self) private var store

    var body: some View {
        if let name = store.currentParty?.name {
            Text(name)
                .textStyle(.sansMd, tone: .secondary, weight: .semibold, lines: 1)
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityAddTraits(.isHeader)
        }
    }
}
