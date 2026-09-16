import SwiftUI

/// Unified negative actions section for account deletion.
struct AccountDangerSection: View {
    @Binding var confirmDelete: Bool

    @Environment(AuthController.self) private var auth

    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
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
            confirmDelete: .constant(false)
        )
        .padding()
    }
}
