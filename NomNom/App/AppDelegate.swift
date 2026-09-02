import UIKit
import UserNotifications

/// Application delegate for lifecycle events and APNs push notification handling.
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Self.configureGlobalTypography()
        Task { @MainActor in
            NotificationManager.shared.start()
        }
        return true
    }

    static func configureGlobalTypography() {
        FontRegistry.registerFonts()
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        // Compact navbar title (when scrolled or inline) -> Inter Light (300 weight)
        if let titleFont = AppTypography.navBarTitleUIFont {
            appearance.titleTextAttributes = [.font: titleFont]
        }
        // Large title on page -> Newsreader Regular (32pt)
        if let largeTitleFont = AppTypography.largePageTitleUIFont {
            appearance.largeTitleTextAttributes = [.font: largeTitleFont]
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
