import SwiftUI

/// Chooses between the sign-in form and the authenticated app.
struct RootView: View {
    @Environment(AuthController.self) private var auth

    var body: some View {
        Group {
            switch auth.phase {
            case .loading:
                LaunchPlaceholder(caption: nil)

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
                LaunchPlaceholder(caption: "Loading your food log…")
                    .task {
                        let fresh = FoodStore(userID: userID)
                        await fresh.load()
                        store = fresh
                    }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: store?.isProfileSetup)
    }
}

struct LaunchPlaceholder: View {
    let caption: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
            ProgressView()
            if let caption {
                Text(caption)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
