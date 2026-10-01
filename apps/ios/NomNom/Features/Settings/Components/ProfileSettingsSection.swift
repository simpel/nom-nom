import SwiftUI

/// Profile editing section in Settings.
struct ProfileSettingsSection: View {
    @Binding var confirmSignOut: Bool

    @Environment(FoodStore.self) private var store

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var didLoadProfile = false

    var body: some View {
        SectionCard("Your Profile") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    UserAvatar(
                        name: "\(firstName) \(lastName)",
                        photoPath: store.myProfile?.photoPath,
                        size: 48
                    )

                    VStack(spacing: 0) {
                        Input(label: "First", placeholder: "First name", text: $firstName, size: .sm)
                            .textContentType(.givenName)
                            .onSubmit(saveProfile)
                        Divider()
                            .padding(.vertical, DS.Spacing.sm)
                        Input(label: "Last", placeholder: "Last name", text: $lastName, size: .sm)
                            .textContentType(.familyName)
                            .onSubmit(saveProfile)
                    }
                }

                Text("This is the name other dinner party members see when you share meals and rate dishes.")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textSecondary)

                Divider()

                AppButton(
                    "Sign out",
                    variant: .destructive,
                    style: .ghost,
                    size: .md,
                    isFullWidth: true
                ) {
                    confirmSignOut = true
                }
            }
        }
        .onAppear(perform: loadProfileIfNeeded)
    }

    private func loadProfileIfNeeded() {
        guard !didLoadProfile else { return }
        didLoadProfile = true
        firstName = store.myProfile?.firstName ?? ""
        lastName = store.myProfile?.lastName ?? ""
    }

    private func saveProfile() {
        Task { await store.updateProfile(firstName: firstName, lastName: lastName) }
    }
}
