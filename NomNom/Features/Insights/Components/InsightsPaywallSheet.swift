import SwiftUI
import RevenueCat

struct InsightsPaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let onPurchaseCompleted: (CustomerInfo) -> Void
    let onRestoreCompleted: (CustomerInfo) -> Void
    
    @State private var offerings: Offerings?
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DS.Spacing.section) {
                        headerSection
                        featuresSection
                        packagesSection
                    }
                    .padding(.vertical, DS.Spacing.sectionCompact)
                }
                
                footerSection
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.textPrimary)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .task {
                await fetchOfferings()
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        PageHeader(
            title: "Nom Nom Pro",
            subtitle: "Unlock your group's taste profiles, get advanced meal suggestions, and never wonder what to eat again.",
            alignment: .center
        )
        .padding(.top, DS.Spacing.screenTop)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            featureRow("Unlimited meal suggestions")
            featureRow("Detailed group taste insights")
            featureRow("AI-powered flavor profiles")
            featureRow("Priority support")
        }
        .padding(.horizontal, DS.Spacing.sectionCompact)
    }
    
    private func featureRow(_ text: String) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "checkmark")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(DS.Color.accent)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(DS.Color.textPrimary)
            Spacer(minLength: 0)
        }
    }
    
    @ViewBuilder
    private var packagesSection: some View {
        if let currentOffering = offerings?.current {
            VStack(spacing: DS.Spacing.sm) {
                if let monthly = currentOffering.monthly {
                    packageCard(package: monthly, title: "Monthly", subtitle: "Flexible billing")
                }
                if let annual = currentOffering.annual {
                    packageCard(package: annual, title: "Yearly", subtitle: "Save 33%", isBestValue: true)
                }
            }
            .padding(.horizontal, DS.Spacing.screenHorizontal)
        } else {
            ProgressView()
                .padding()
        }
    }
    
    private func packageCard(package: Package, title: String, subtitle: String, isBestValue: Bool = false) -> some View {
        let isSelected = selectedPackage?.identifier == package.identifier
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedPackage = package
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: DS.Spacing.xs) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(isSelected ? DS.Color.accent : DS.Color.textPrimary)
                        
                        if isBestValue {
                            Text("Best Value")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(DS.Color.accent)
                                .clipShape(Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                
                Spacer()
                
                Text(package.localizedPriceString)
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)
            }
            .padding(DS.Spacing.md)
            .background(DS.Color.panel)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected ? DS.Color.accent : DS.Color.line,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
    
    private var footerSection: some View {
        VStack(spacing: DS.Spacing.md) {
            AppButton(
                "Subscribe",
                variant: .primary,
                style: .normal,
                size: .xl,
                isFullWidth: true,
                isPending: isPurchasing,
                disabled: selectedPackage == nil
            ) {
                Task { await purchaseSelectedPackage() }
            }
            
            AppButton(
                "Restore Purchases",
                variant: .neutral,
                style: .ghost,
                size: .sm,
                isPending: isRestoring
            ) {
                Task { await restorePurchases() }
            }
        }
        .padding(.horizontal, DS.Spacing.screenHorizontal)
        .padding(.bottom, DS.Spacing.screenBottom)
        .padding(.top, DS.Spacing.md)
        .background(DS.Color.bg.ignoresSafeArea(edges: .bottom))
    }
    
    // MARK: - Actions
    
    @MainActor
    private func fetchOfferings() async {
        do {
            let fetchedOfferings = try await Purchases.shared.offerings()
            self.offerings = fetchedOfferings
            // Default select annual if available
            self.selectedPackage = fetchedOfferings.current?.annual ?? fetchedOfferings.current?.monthly
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    private func purchaseSelectedPackage() async {
        guard let package = selectedPackage else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if !result.userCancelled {
                onPurchaseCompleted(result.customerInfo)
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    private func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            onRestoreCompleted(customerInfo)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
