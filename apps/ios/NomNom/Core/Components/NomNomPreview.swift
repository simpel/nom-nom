import SwiftUI

/// Standard environment and navigation wrapper for Xcode SwiftUI `#Preview`s.
///
/// Automatically injects mock `FoodStore`, `AuthController`, and `NotificationManager`
/// so any view or component can be previewed immediately in the Canvas without running the simulator.
@MainActor
struct NomNomPreview<Content: View>: View {

    var store: FoodStore
    var auth: AuthController
    var inNavigationStack: Bool
    @ViewBuilder var content: (FoodStore) -> Content

    @MainActor
    init(
        store: FoodStore? = nil,
        auth: AuthController? = nil,
        inNavigationStack: Bool = true,
        @ViewBuilder content: @escaping (FoodStore) -> Content
    ) {
        self.store = store ?? .preview
        self.auth = auth ?? .preview
        self.inNavigationStack = inNavigationStack
        self.content = content
    }

    @MainActor
    init(
        store: FoodStore? = nil,
        auth: AuthController? = nil,
        inNavigationStack: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(store: store, auth: auth, inNavigationStack: inNavigationStack) { _ in
            content()
        }
    }

    var body: some View {
        Group {
            if inNavigationStack {
                NavigationStack {
                    content(store)
                }
            } else {
                content(store)
            }
        }
        .environment(store)
        .environment(auth)
        .environment(NotificationManager.shared)
    }
}
