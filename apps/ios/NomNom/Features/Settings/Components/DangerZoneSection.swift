import SwiftUI

/// Account deletion danger zone section in Settings.
struct DangerZoneSection: View {
    @Binding var confirmDelete: Bool
    @Environment(AuthController.self) private var auth

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                AppButton(
                    "Delete account",
                    variant: .destructive,
                    style: .ghost,
                    size: .md,
                    isFullWidth: true,
                    isPending: auth.isWorking,
                    disabled: auth.isWorking
                ) {
                    confirmDelete = true
                }

                Text("Permanently removes your account, your meals and their photos. Other dinner party members keep their own food logs.")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
    }
}
