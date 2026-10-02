import UIKit
import UserNotifications
import RevenueCat

/// Application delegate for lifecycle events and APNs push notification handling.
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Self.configureGlobalTypography()
        
        // Initialize RevenueCat for in-app billing
        Purchases.configure(withAPIKey: BillingConfig.revenueCatKey)

        Task { @MainActor in
            Purchases.shared.delegate = EntitlementStore.shared
            NotificationManager.shared.start()
        }
        return true
    }

    static func configureGlobalTypography() {
        // Fonts are registered through INFOPLIST_KEY_UIAppFonts.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        // Compact navbar title (when scrolled or inline) -> system semibold
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        // Large title on page -> Newsreader 72pt display cut at serif-lg
        let largeTitle = DS.TextStyle.serifLg
        if let name = largeTitle.fontName(), let largeTitleFont = UIFont(name: name, size: largeTitle.size) {
            appearance.largeTitleTextAttributes = [
                .font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: largeTitleFont)
            ]
        }
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            NotificationManager.shared.handleDeviceToken(deviceToken, store: nil)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Normal during simulator runs or when APNs entitlement is not yet deployed
    }
}
