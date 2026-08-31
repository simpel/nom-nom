import SwiftUI

/// Dedicated sheet for editing personal profile information, signing out, and deleting account.
struct ProfileSheetView: View {
    @Environment(FoodStore.self) private var store
    @Environment(AuthController.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var myEmoji = "🧑"
    @State private var didLoadProfile = false
    @State private var confirmSignOut = false
    @State private var confirmDelete = false

    private let emojiChoices = ["🧒", "👦", "👧", "🧑", "👩", "👨", "👶", "🐣", "🦊", "🐻", "🐼", "🦁", "🐧", "🦄"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Menu {
                            ForEach(emojiChoices, id: \.self) { emoji in
                                Button(emoji) {
                                    myEmoji = emoji
                                    saveProfile()
                                }
                            }
                        } label: {
                            Text(myEmoji)
                                .font(.system(size: 40))
                                .padding(6)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(Circle())
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
                    .padding(.vertical, 4)
                } header: {
                    Text("Profile Details")
                } footer: {
                    Text("This is how other dinner party members will see you.")
                }

                Section {
                    Button(role: .destructive) {
                        confirmSignOut = true
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                DangerZoneSection(confirmDelete: $confirmDelete)
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveProfile()
                        dismiss()
                    }
                }
            }
            .onAppear(perform: loadProfileIfNeeded)
            .alert("Sign out?", isPresented: $confirmSignOut) {
                Button("Sign out", role: .destructive) {
                    Task { await auth.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your food log stays on the server and comes back when you sign in again.")
            }
            .alert("Delete your account?", isPresented: $confirmDelete) {
                Button("Delete everything", role: .destructive) {
                    Task { await auth.deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes your account, every meal and photo you've logged, and the people you track. It cannot be undone.")
            }
        }
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
