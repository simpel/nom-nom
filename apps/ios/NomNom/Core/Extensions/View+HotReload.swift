import SwiftUI

extension View {

    /// Wraps the view hierarchy in a hot-reloading container in DEBUG builds.
    ///
    /// When paired with InjectionNext or InjectionIII, file saves automatically trigger
    /// dynamic replacement and view re-evaluation without restarting the app or resetting state.
    /// In non-DEBUG builds, this is an inlined identity transform with zero runtime overhead.
    @ViewBuilder
    func enableHotReload() -> some View {
        #if DEBUG
        HotReloadHost {
            self
        }
        #else
        self
        #endif
    }
}
