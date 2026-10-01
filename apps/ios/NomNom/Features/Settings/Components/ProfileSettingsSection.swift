import SwiftUI

/// Profile editing section in Settings: avatar and name fields, saved on return.
struct ProfileSettingsSection: View {
    @Environment(FoodStore.self) private var store

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var didLoadProfile = false

    var body: some View {
        NameFieldsCard(
            "Your Profile",
            firstName: $firstName,
            lastName: $lastName,
            placeholder: "Required",
            footnote: "This is the name other dinner party members see when you share meals and rate dishes.",
            onSubmit: saveProfile
        ) {
            Avatar(
                name: "\(firstName) \(lastName)",
                photoPath: store.myProfile?.photoPath,
                size: .lg
            )
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
