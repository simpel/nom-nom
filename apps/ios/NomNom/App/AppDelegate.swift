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
        // The DS names no navigation-bar style (logged in DS-GAPS.md); these are the
        // closest documented steps. Inline title: `sans-lg` semibold — README
        // "Typography": "sans-lg … sheet and reason titles … (each sets semibold itself)".
        appearance.titleTextAttributes = [
            .font: DS.TextStyle.sansLg.uiFont(weight: .semibold)
        ]
        // Large title: `serif-lg` — README "Typography": "serif-lg … page and hero titles".
        appearance.largeTitleTextAttributes = [
            .font: DS.TextStyle.serifLg.uiFont()
        ]
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
