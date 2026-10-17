import SwiftUI

/// The "Keep screen on" setting: while a recipe or cook mode is open and it is on, the
/// screen never dims. A device setting (`@AppStorage`), on by default, shown as a toggle
/// on the recipe page and in cook mode.
enum KeepScreenOn {
    static let storageKey = "keepScreenOn"

    /// Screens that want the screen on right now. The recipe page stays open under cook
    /// mode, so closing cook mode must not let the screen dim while the recipe is up.
    @MainActor private static var holders = 0

    @MainActor static func acquire() { holders += 1; apply() }
    @MainActor static func release() { holders = max(0, holders - 1); apply() }

    @MainActor static func apply() {
        let isOn = UserDefaults.standard.object(forKey: storageKey) as? Bool ?? true
        UIApplication.shared.isIdleTimerDisabled = holders > 0 && isOn
    }
}

private struct KeepScreenOnModifier: ViewModifier {
    @AppStorage(KeepScreenOn.storageKey) private var isOn = true

    func body(content: Content) -> some View {
        content
            .onAppear { KeepScreenOn.acquire() }
            .onDisappear { KeepScreenOn.release() }
            .onChange(of: isOn) { KeepScreenOn.apply() }
    }
}

extension View {
    /// Keeps the screen from dimming while this view is on screen, if the person's
    /// "Keep screen on" setting is on.
    func keepsScreenOn() -> some View {
        modifier(KeepScreenOnModifier())
    }
}
