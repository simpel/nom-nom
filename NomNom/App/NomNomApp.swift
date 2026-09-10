import SwiftUI

@main
struct NomNomApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State private var auth = AuthController()

    init() {
        AppDelegate.configureGlobalTypography()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(NotificationManager.shared)
                .task {
                    auth.start()
                }
                .onChange(of: scenePhase) { _, phase in
                    // The user may flip the OS notification switch while away;
                    // re-read it so the settings UI and re-registration stay honest.
                    if phase == .active {
                        Task { await NotificationManager.shared.refreshStatus() }
                    }
                }
        }
    }
}
