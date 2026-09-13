import Foundation

/// Configuration for RevenueCat and in-app billing.
///
/// Use the `#if DEBUG` macro to switch between your Sandbox keys (for local testing 
/// and TestFlight without real charges) and your Production keys (for the live App Store).
enum BillingConfig {
    
    #if DEBUG
    /// RevenueCat Public API Key for Sandbox / Development
    static let revenueCatKey = "test_POkASvbxfrOxxzZbnPjsTqLLEzG"
    #else
    /// RevenueCat Public API Key for Production
    /// (Replace with live key when deploying)
    static let revenueCatKey = "test_POkASvbxfrOxxzZbnPjsTqLLEzG"
    #endif
    
    /// The Entitlement ID set up in your RevenueCat Dashboard
    static let entitlementID = "nomnom_let_s_eat_together_pro"
}
