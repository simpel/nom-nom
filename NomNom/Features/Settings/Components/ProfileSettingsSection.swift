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
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Text(firstName.prefix(1).uppercased())
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                    }

                    VStack(spacing: 8) {
                        TextField("First name", text: $firstName)
                            .textContentType(.givenName)
                            .onSubmit(saveProfile)
                        Divider()
                        TextField("Last name", text: $lastName)
                            .textContentType(.familyName)
                            .onSubmit(saveProfile)
                    }
                }

                Text("This is the name other dinner party members see when you share meals and rate dishes.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Divider()

                Button(role: .destructive) {
                    confirmSignOut = true
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
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
