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
        Section {
            HStack(spacing: 12) {
                Menu {
                    ForEach(emojiChoices, id: \.self) { emoji in
                        Button(emoji) { myEmoji = emoji; saveProfile() }
                    }
                } label: {
                    Text(myEmoji).font(.title2)
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

            Button(role: .destructive) {
                confirmSignOut = true
            } label: {
                Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } header: {
            Text("Your Profile")
        } footer: {
            Text("This is the name other dinner party members see when you share meals and rate dishes.")
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
