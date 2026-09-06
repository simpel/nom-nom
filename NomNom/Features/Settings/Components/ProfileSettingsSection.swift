import SwiftUI

/// Profile editing section in Settings.
struct ProfileSettingsSection: View {
    let emojiChoices: [String]
    @Binding var confirmSignOut: Bool

    @Environment(FoodStore.self) private var store

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var myEmoji = "🧑"
    @State private var didLoadProfile = false

    var body: some View {
        SectionCard("Your Profile") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(DS.Color.accentSoft)
                            .frame(width: 48, height: 48)
                        Text(firstName.prefix(1).uppercased())
                            .font(.title3.weight(.bold))
                            .foregroundStyle(DS.Color.accentText)
                    }

                    VStack(spacing: 8) {
                        Input("First name", text: $firstName, size: .sm)
                            .textContentType(.givenName)
                            .onSubmit(saveProfile)
                        Input("Last name", text: $lastName, size: .sm)
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
        myEmoji = store.myProfile?.avatarEmoji ?? "🧑"
    }

    private func saveProfile() {
        Task { await store.updateProfile(firstName: firstName, lastName: lastName, emoji: myEmoji) }
    }
}
