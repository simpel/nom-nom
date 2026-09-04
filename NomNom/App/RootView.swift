import SwiftUI

/// Chooses between the sign-in form and the authenticated app.
struct RootView: View {
    @Environment(AuthController.self) private var auth

    var body: some View {
        Group {
            switch auth.phase {
            case .loading:
                LaunchPlaceholder()

            case .signedOut:
                SignInView()

            case .signedIn(let userID):
                SignedInView(userID: userID)
                    .id(userID)
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
        .animation(.easeInOut(duration: 0.35), value: store?.isProfileSetup)
        .onChange(of: NotificationManager.shared.deviceToken) { _, newToken in
            if let newToken, let store {
                Task {
                    await store.registerDeviceToken(newToken)
                }
            }
        }
    }
}

struct LaunchPlaceholder: View {
    init(caption: String? = nil) {}

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            Text("NomNom")
                .font(AppTypography.displayXL)
                .foregroundStyle(DS.Color.textPrimary)
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Color.bg)
    }
}
