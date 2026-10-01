// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// Account actions at the foot of Settings and the profile sheet, in one Card:
/// "Sign out" (destructive ghost) and "Delete account" (destructive outline) with
/// a footnote. Owns the confirmation alerts (`View+AccountConfirmations.swift`).
struct AccountActionsSection: View {
    var includesSignOut: Bool = true

    @Environment(AuthController.self) private var auth
    @State private var confirmSignOut = false
    @State private var confirmDelete = false

    var body: some View {
        Card(spacing: DS.Spacing.s2) {
            if includesSignOut {
                AppButton("Sign out", variant: .destructive, appearance: .ghost, fullWidth: true) {
                    confirmSignOut = true
                }
            }
            AppButton(
                "Delete account",
                variant: .destructive,
                appearance: .outline,
                fullWidth: true,
                isLoading: auth.isWorking
            ) {
                confirmDelete = true
            }
            Text("Permanently removes your account, your meals and their photos. Other dinner party members keep their own food logs.")
                .textStyle(.sansXs, tone: .secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .signOutConfirmation(isPresented: $confirmSignOut)
        .deleteAccountConfirmation(isPresented: $confirmDelete)
    }
}

#Preview("Light") {
    NomNomPreview { _ in
        AccountActionsSection().padding(DS.Spacing.gutter)
    }
}

#Preview("Dark") {
    NomNomPreview { _ in
        AccountActionsSection(includesSignOut: false).padding(DS.Spacing.gutter)
    }
    .preferredColorScheme(.dark)
}
