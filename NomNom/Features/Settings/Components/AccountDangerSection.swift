import SwiftUI

/// Unified negative actions section for signing out and deleting the account.
struct AccountDangerSection: View {
    @Binding var confirmSignOut: Bool
    @Binding var confirmDelete: Bool

    @Environment(AuthController.self) private var auth

    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            AppButton(
                "Sign out",
                variant: .destructive,
                style: .outlined,
                size: .md,
                isFullWidth: true
            ) {
                confirmSignOut = true
            }

            AppButton(
                "Delete account",
                variant: .destructive,
                style: .outlined,
                size: .md,
                isFullWidth: true,
                isPending: auth.isWorking,
                disabled: auth.isWorking
            ) {
                confirmDelete = true
            }
        }
    }
}

#Preview {
    NomNomPreview { _ in
        AccountDangerSection(
            confirmSignOut: .constant(false),
            confirmDelete: .constant(false)
        )
        .padding()
    }
}
