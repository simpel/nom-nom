import SwiftUI

@main
struct NomNomApp: App {
    @State private var auth = AuthController()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .task {
                    auth.start()
                    #if DEBUG
                    await DevSignIn.runIfRequested(auth)
                    #endif
                }
        }
    }
}
