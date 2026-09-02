import SwiftUI

@main
struct NomNomApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
                    #if DEBUG
                    if DevSignIn.isRequested {
                        await DevSignIn.run(auth)
                        return
                    }
                    #endif
                    auth.start()
                }
        }
    }
}
