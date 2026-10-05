import SwiftUI

extension View {
    /// Presents the Nom Nom Pro paywall and applies the purchase or restore result to the
    /// entitlement store. Every "Unlock with Pro" button (ProCard, ProGate) opens it.
    func proPaywall(isPresented: Binding<Bool>) -> some View {
        modifier(ProPaywallModifier(isPresented: isPresented))
    }
}

private struct ProPaywallModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Environment(EntitlementStore.self) private var entitlements

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            InsightsPaywallSheet(
                onPurchaseCompleted: { info in
                    entitlements.apply(info)
                    isPresented = false
                },
                onRestoreCompleted: { info in
                    entitlements.apply(info)
                    isPresented = false
                }
            )
        }
    }
}
