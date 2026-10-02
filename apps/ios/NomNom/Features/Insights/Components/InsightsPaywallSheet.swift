import SwiftUI
import RevenueCat

/// The Nom Nom Pro paywall, as a BottomSheet: a centred PageHeader, the Pro features as
/// ListRows, the plans (PaywallPackageCard) and a pinned footer with Subscribe
/// (`pro solid lg`) and Restore purchases (`secondary ghost sm`).
struct InsightsPaywallSheet: View {
    let onPurchaseCompleted: (CustomerInfo) -> Void
    let onRestoreCompleted: (CustomerInfo) -> Void

    @State private var offerings: Offerings?
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?

    private static let features = [
        "Unlimited meal suggestions",
        "Detailed group taste insights",
        "AI-powered flavor profiles",
        "Priority support",
    ]

    var body: some View {
        NavigationStack {
            SheetBody {
                // PageHeader README: one sentence, centred for the paywall.
                PageHeader(
                    "Know what your table loves",
                    subtitle: "Taste profiles for your group and meal suggestions they will eat.",
                    eyebrow: "Nom Nom Pro",
                    align: .center
                )

                Card(layout: .list) {
                    ForEach(Self.features, id: \.self) { feature in
                        ListRow(feature, leading: .icon("checkmark"), size: .sm)
                    }
                }

                packagesSection
            }
            .safeAreaInset(edge: .bottom) { footerSection }
            .screenTitle("", displayMode: .inline)
            .sheetCloseToolbar()
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
        .dsSheet()
    }

    // MARK: - Sections

    @ViewBuilder
    private var packagesSection: some View {
        if let currentOffering = offerings?.current {
            VStack(spacing: DS.Spacing.s3) {
                // Yearly leads and always carries the Pro treatment — it's the plan we
                // want chosen, so it should be seen and read as "premium" first, not
                // discovered by scrolling past Monthly.
                if let annual = currentOffering.annual {
                    packageCard(annual, title: "Yearly", subtitle: "Save 33%", isBestValue: true)
                }
                if let monthly = currentOffering.monthly {
                    packageCard(monthly, title: "Monthly", subtitle: "Flexible billing")
                }
            }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
        }
    }

    private func packageCard(_ package: Package, title: String, subtitle: String, isBestValue: Bool = false) -> some View {
        PaywallPackageCard(
            package: package,
            title: title,
            subtitle: subtitle,
            isBestValue: isBestValue,
            isSelected: selectedPackage?.identifier == package.identifier
        ) {
            withAnimation(DS.Motion.state) {
                selectedPackage = package
            }
        }
    }

    private var footerSection: some View {
        VStack(spacing: DS.Spacing.s2) {
            AppButton("Subscribe", variant: .pro, size: .lg, fullWidth: true, isLoading: isPurchasing) {
                Task { await purchaseSelectedPackage() }
            }
            .disabled(selectedPackage == nil)

            AppButton("Restore purchases", variant: .secondary, appearance: .ghost, size: .sm, isLoading: isRestoring) {
                Task { await restorePurchases() }
            }
        }
        // SheetBody's side padding (`spacing-5`), `spacing-4` above and `spacing-2` below.
        .padding(.horizontal, DS.Spacing.s5)
        .padding(.top, DS.Spacing.s4)
        .padding(.bottom, DS.Spacing.s2)
        .background(DS.Color.sheet)
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
