import SwiftUI

/// Account deletion danger zone section in Settings.
struct DangerZoneSection: View {
    @Binding var confirmDelete: Bool
    @Environment(AuthController.self) private var auth

    var body: some View {
        Section {
            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                HStack {
                    Label("Delete account", systemImage: "trash")
                    if auth.isWorking {
                        Spacer()
                        ProgressView().controlSize(.small)
                    }
                }
            }
            .disabled(auth.isWorking)
        } footer: {
            Text("Permanently removes your account, your meals and their photos. Other dinner party members keep their own food logs.")
        }
    }
}
