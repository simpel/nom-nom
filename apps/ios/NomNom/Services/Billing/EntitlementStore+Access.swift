import Foundation

extension EntitlementStore {
    // TODO: remove — temporarily disables the Pro lock so every screen is reachable while
    // they're still being built. Flip back to `false` (or delete) once done.
    static let paywallDisabled = true

    /// Whether Pro content shows unlocked: the entitlement, or the temporary bypass above.
    /// Every gate (ProGate, ProSection, ProLinkCard) reads this, never `isPro` directly.
    var hasProAccess: Bool { isPro || Self.paywallDisabled }
}
