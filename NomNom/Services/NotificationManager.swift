import SwiftUI
import UserNotifications
import os

/// Manages device notification authorization, APNs token registration, and foreground presentation.
@Observable
@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var deviceToken: String?
    var pendingRateMealID: UUID?

    private static let log = Logger(subsystem: "se.joelsanden.nomnom", category: "notifications")

    override private init() {
        super.init()
    }

    func start() {
        UNUserNotificationCenter.current().delegate = self
        Task { await refreshStatus() }
    }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await refreshStatus()
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return granted
        } catch {
            Self.log.error("Failed to request notification permission: \(error.localizedDescription)")
            await refreshStatus()
            return false
        }
    }

    func handleDeviceToken(_ tokenData: Data, store: FoodStore?) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        Self.log.info("Received APNs device token: \(token.prefix(8))…")

        #if DEBUG
        let environment = "sandbox"
        #else
        let environment = "production"
        #endif

        if let store {
            Task {
                await store.registerDeviceToken(token, environment: environment)
            }
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Display banner and sound even if app is in foreground
        completionHandler([.banner, .badge, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let mealIdString = (userInfo["mealId"] as? String) ?? (userInfo["meal_id"] as? String)
        if let mealIdString, let id = UUID(uuidString: mealIdString) {
            Task { @MainActor in
                NotificationManager.shared.pendingRateMealID = id
            }
        }
        completionHandler()
    }
}
