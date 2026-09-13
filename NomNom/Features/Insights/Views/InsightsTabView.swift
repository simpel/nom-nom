import SwiftUI
import RevenueCat

struct InsightsTabView: View {
    @State private var isPro: Bool = false
    @State private var showPaywall: Bool = false
    @State private var isLoading: Bool = true
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .controlSize(.large)
                } else if isPro {
                    // Show the real dashboard
                    ProDashboardView()
                } else {
                    // Show the Teaser View with Paywall Footer
                    FreeTeaserView(onUpgradeTapped: {
                        showPaywall = true
                    })
                }
            }
            .navigationTitle("Insights")
            .toolbar {
                // Customer Center Support (Best Practice)
                if isPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Manage Sub") {
                            // Native Customer Center presentation
                            // presentCustomerCenter = true
                        }
                    }
                }
            }
        }
        .task {
            await checkEntitlement()
        }
        .sheet(isPresented: $showPaywall) {
            InsightsPaywallSheet(
                onPurchaseCompleted: { customerInfo in
                    handle(customerInfo: customerInfo)
                    showPaywall = false
                },
                onRestoreCompleted: { customerInfo in
                    handle(customerInfo: customerInfo)
                    showPaywall = false
                }
            )
        }
    }
    
    /// Checks the local cache / backend for the user's current entitlement
    private func checkEntitlement() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            handle(customerInfo: customerInfo)
        } catch {
            print("Failed to fetch customer info: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    /// Parses CustomerInfo and updates state
    private func handle(customerInfo: CustomerInfo) {
        let isEntitled = customerInfo.entitlements.all[BillingConfig.entitlementID]?.isActive == true
        self.isPro = isEntitled
        self.isLoading = false
    }
}

// MARK: - Placeholder Views

struct ProDashboardView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your group prefers Savory meals with Garlic.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                // Add the Dashboard UI from our HTML prototype here later
                Text("Dashboard Content Placeholder")
            }
            .padding()
        }
    }
}

struct FreeTeaserView: View {
    let onUpgradeTapped: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background Layer: The Teaser + Skeletons
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.section) {
                    PageHeader(
                        title: "Group Insights",
                        subtitle: "Your group prefers Savory meals with Garlic...",
                        alignment: .leading
                    )
                    .padding(.top, DS.Spacing.screenTop)
                    
                    SkeletonDashboardView()
                        .padding(.horizontal, DS.Spacing.screenHorizontal)
                }
                .padding(.bottom, 300) // Huge space for the overlay to breathe
            }
            .scrollDisabled(true) // Freeze the background
            
            // Foreground Layer: The Gradient Overlay + Upsell CTA
            VStack(spacing: DS.Spacing.md) {
                Text("See exactly what to cook next.")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DS.Color.textPrimary)
                
                Text("Unlock Pro to reveal your group's complete flavor profile, top ingredients, and AI-powered meal suggestions.")
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.md)
                
                AppButton(
                    "Unlock Pro",
                    variant: .primary,
                    style: .normal,
                    size: .xl,
                    isFullWidth: true
                ) {
                    onUpgradeTapped()
                }
                .padding(.top, DS.Spacing.sm)
            }
            .padding(.horizontal, DS.Spacing.screenHorizontal)
            .padding(.top, 120)
            // Critical fix: We must clear the custom floating tab bar completely
            .padding(.bottom, 140)
            .background(
                LinearGradient(
                    colors: [
                        DS.Color.bg.opacity(0.0),
                        DS.Color.bg.opacity(0.95),
                        DS.Color.bg,
                        DS.Color.bg
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Skeleton Components

struct SkeletonDashboardView: View {
    var body: some View {
        VStack(spacing: DS.Spacing.sectionCompact) {
            
            // Fake Card: Flavor Profile (Bar Chart)
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                // Fake Header
                RoundedRectangle(cornerRadius: 4)
                    .fill(DS.Color.lineStrong)
                    .frame(width: 140, height: 20)
                
                HStack(alignment: .bottom, spacing: DS.Spacing.md) {
                    // Staggered heights to look like a chart
                    ForEach([40, 80, 100, 60, 50], id: \.self) { height in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DS.Color.accentSoft)
                            .frame(maxWidth: .infinity)
                            .frame(height: CGFloat(height))
                    }
                }
                .frame(height: 100)
            }
            .padding(DS.Spacing.md)
            .background(DS.Color.panel) // The panel will now actually be visible
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Fake Card: Top Ingredients (List)
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                // Fake Header
                RoundedRectangle(cornerRadius: 4)
                    .fill(DS.Color.lineStrong)
                    .frame(width: 160, height: 20)
                
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: DS.Spacing.sm) {
                        Circle()
                            .fill(DS.Color.accentSoft)
                            .frame(width: 40, height: 40)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DS.Color.lineStrong)
                                .frame(width: 120, height: 14)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DS.Color.line)
                                .frame(width: 80, height: 10)
                        }
                    }
                }
            }
            .padding(DS.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.panel)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .opacity(0.65) // Tantalizingly faded, but structural integrity is intact
    }
}
