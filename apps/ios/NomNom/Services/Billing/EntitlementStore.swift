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

    private(set) var isPro: Bool = false
    private(set) var customerInfo: CustomerInfo?

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
        isPro = false
    }

    func apply(_ info: CustomerInfo) {
        customerInfo = info
        isPro = info.entitlements[BillingConfig.entitlementID]?.isActive == true
    }

    // MARK: - PurchasesDelegate

    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.apply(customerInfo)
        }
    }
}
