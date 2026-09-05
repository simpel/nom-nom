import SwiftUI

/// Unified negative actions section for signing out and deleting the account.
struct AccountDangerSection: View {
    @Binding var confirmSignOut: Bool
    @Binding var confirmDelete: Bool

    @Environment(AuthController.self) private var auth

    var body: some View {
        SectionCard {
            VStack(spacing: 12) {
                Button(role: .destructive) {
                    confirmSignOut = true
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Divider()

                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    HStack {
                        Label("Delete account", systemImage: "trash")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)

                        if auth.isWorking {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .disabled(auth.isWorking)
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
