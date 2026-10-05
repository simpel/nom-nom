import Foundation
import UserNotifications

/// One running step timer in cook mode. Counts down to `endsAt` and schedules a local
/// notification for then, so the cook hears it with the phone locked.
@Observable
@MainActor
final class CookModeTimer {
    private(set) var endsAt: Date?
    /// The step (index) the timer belongs to.
    private(set) var stepIndex: Int?

    private static let requestID = "cook-mode-timer"

    var isRunning: Bool { endsAt.map { $0 > .now } ?? false }

    func start(minutes: Int, stepIndex: Int, recipeName: String) {
        let end = Date.now.addingTimeInterval(TimeInterval(minutes * 60))
        endsAt = end
        self.stepIndex = stepIndex

        let content = UNMutableNotificationContent()
        content.title = recipeName
        content.body = "Step \(stepIndex + 1): your \(minutes) min timer is done."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestID])
        Task {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
            try? await center.add(UNNotificationRequest(identifier: Self.requestID, content: content, trigger: trigger))
        }
    }

    func stop() {
        endsAt = nil
        stepIndex = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.requestID])
    }

    /// "12:04" left at `now`.
    func remainingText(at now: Date) -> String {
        guard let endsAt else { return "" }
        let seconds = max(0, Int(endsAt.timeIntervalSince(now).rounded(.up)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
