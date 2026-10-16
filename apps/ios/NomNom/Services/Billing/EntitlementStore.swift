import Foundation
import Observation
import RevenueCat

/// Source of truth for Nom Nom Pro entitlement state.
///
/// Ties RevenueCat's `appUserID` to the signed-in Supabase user via `signIn`/`signOut`
/// (called from `RootView` as `AuthController.userID` changes), and stays current
/// afterwards via `PurchasesDelegate` pushes.
@Observable
@MainActor
final class EntitlementStore: NSObject, PurchasesDelegate {
    static let shared = EntitlementStore()

    /// What RevenueCat says; `isPro` is this, unless a debug build overrides it.
    private(set) var isEntitled: Bool = false
    private(set) var customerInfo: CustomerInfo?

    var isPro: Bool {
        #if DEBUG
        return debugProOverride ?? isEntitled
        #else
        return isEntitled
        #endif
    }

    #if DEBUG
    private static let debugProKey = "debug.proOverride"

    /// Debug builds only: forces Pro on (`true`) or off (`false`); `nil` follows RevenueCat.
    /// Persisted so it survives relaunches. Toggled from Settings → Debug tools.
    var debugProOverride: Bool? = {
        UserDefaults.standard.object(forKey: debugProKey) as? Bool
    }() {
        didSet {
            if let debugProOverride {
                UserDefaults.standard.set(debugProOverride, forKey: Self.debugProKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.debugProKey)
            }
        }
    }
    #endif

    private override init() {
        super.init()
    }

    func signIn(userID: UUID) async {
        if let (info, _) = try? await Purchases.shared.logIn(userID.uuidString) {
            apply(info)
        }
    }

    func signOut() async {
        _ = try? await Purchases.shared.logOut()
        customerInfo = nil
        isEntitled = false
    }

    func apply(_ info: CustomerInfo) {
        customerInfo = info
        isEntitled = info.entitlements[BillingConfig.entitlementID]?.isActive == true
    }

    // MARK: - PurchasesDelegate

    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.apply(customerInfo)
        }
    }
}
