import SwiftUI

/// Chooses between the sign-in form and the authenticated app.
struct RootView: View {
    @Environment(AuthController.self) private var auth

    var body: some View {
        Group {
            switch auth.phase {
            case .loading:
                LaunchPlaceholder()
                    .transition(.opacity)

            case .signedOut:
                SignInView()
                    .transition(.opacity)

            case .signedIn(let userID):
                SignedInView(userID: userID)
                    .id(userID)
                    .transition(.opacity)
            }
        }
        .animation(DS.Motion.layout, value: auth.phase)
        .task(id: auth.userID) {
            if let userID = auth.userID {
                await EntitlementStore.shared.signIn(userID: userID)
            } else {
                await EntitlementStore.shared.signOut()
            }
        }
    }
}

/// Owns the store lifecycle for one signed-in account.
private struct SignedInView: View {
    let userID: UUID

    @State private var store: FoodStore?

    var body: some View {
        Group {
            if let store {
                if store.isProfileSetup {
                    RootTabView()
                        .environment(store)
                        .transition(.opacity)
                } else {
                    OnboardingView()
                        .environment(store)
                        .transition(.opacity)
                }
            } else {
                LaunchPlaceholder()
                    .task {
                        let fresh = FoodStore(userID: userID)
                        await fresh.load()
                        if let token = NotificationManager.shared.deviceToken {
                            await fresh.registerDeviceToken(token)
                        }
                        store = fresh
                    }
            }
        }
        .animation(DS.Motion.layout, value: store?.isProfileSetup)
        .onChange(of: NotificationManager.shared.deviceToken) { _, newToken in
            if let newToken, let store {
                Task {
                    await store.registerDeviceToken(newToken)
                }
            }
        }
    }
}

/// The launch screen while the session and store load: the name set in type
/// (README "Logo": "the name is set in type: 'Nom Nom' in Newsreader") over a spinner.
struct LaunchPlaceholder: View {
    init(caption: String? = nil) {}

    var body: some View {
        VStack(spacing: DS.Spacing.s4) {
            Text("Nom Nom")
                .textStyle(.serifLg)
            ProgressView()
                .tint(DS.Color.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Color.bg)
    }
}
