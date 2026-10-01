import SwiftUI
#if DEBUG
import Inject
#endif

/// A container view that observes runtime code injection notifications in DEBUG builds.
///
/// When new code is compiled and injected via InjectionNext or InjectionIII,
/// `HotReloadHost` invalidates and triggers a SwiftUI re-evaluation of its child content.
public struct HotReloadHost<Content: View>: View {

    #if DEBUG
    @ObserveInjection private var inject
    #endif

    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        #if DEBUG
        content()
            .enableInjection()
        #else
        content()
        #endif
    }
}
