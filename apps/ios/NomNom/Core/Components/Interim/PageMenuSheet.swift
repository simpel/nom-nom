import SwiftUI

/// The sheets the page menu opens.
enum PageMenuSheet: String, Identifiable {
    case inbox, profile, settings, paywall
    var id: String { rawValue }
}

/// The content for one page-menu sheet.
struct PageMenuSheetContent: View {
    let sheet: PageMenuSheet

    @Environment(FoodStore.self) private var store
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        switch sheet {
        case .inbox:
            InboxSheetView()
        case .profile:
            NavigationStack {
                PersonDetailView(raterRef: .account(store.userID), isSheet: true)
            }
            .dsSheet()
        case .settings:
            NavigationStack {
                SettingsView()
                    .sheetCloseToolbar()
            }
            .dsSheet()
        case .paywall:
            InsightsPaywallSheet(
                onPurchaseCompleted: { info in
                    entitlements.apply(info)
                    dismiss()
                },
                onRestoreCompleted: { info in
                    entitlements.apply(info)
                    dismiss()
                }
            )
        }
    }
}
