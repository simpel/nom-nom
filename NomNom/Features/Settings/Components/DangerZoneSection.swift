import SwiftUI

/// Account deletion danger zone section in Settings.
struct DangerZoneSection: View {
    @Binding var confirmDelete: Bool
    @Environment(AuthController.self) private var auth

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    HStack {
                        Label("Delete account", systemImage: "trash")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                        if auth.isWorking {
                            Spacer()
                            ProgressView().controlSize(.small)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(auth.isWorking)

                Text("Permanently removes your account, your meals and their photos. Other dinner party members keep their own food logs.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
