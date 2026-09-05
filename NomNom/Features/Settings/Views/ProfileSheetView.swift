import SwiftUI

/// Dedicated sheet for editing personal profile information, photo avatar, notification preferences, and account actions.
struct ProfileSheetView: View {
    @Environment(FoodStore.self) private var store
    @Environment(AuthController.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var photoDraft = FoodStore.PhotosDraft()
    @State private var didLoadProfile = false
    @State private var confirmSignOut = false
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.section) {
                    AssetPhotosPickerSection(
                        draft: $photoDraft,
                        title: "Profile Photo",
                        bucket: SupabaseConfig.profileBucket,
                        maxCount: 1
                    )

                    SectionCard("Profile Details") {
                        VStack(spacing: 8) {
                            TextField("First name", text: $firstName)
                                .textContentType(.givenName)
                                .onSubmit { saveProfile() }
                            Divider()
                            TextField("Last name", text: $lastName)
                                .textContentType(.familyName)
                                .onSubmit { saveProfile() }
                        }
                    }

                    NotificationPreferencesSection()

                    AccountDangerSection(
                        confirmSignOut: $confirmSignOut,
                        confirmDelete: $confirmDelete
                    )
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("My Profile", displayMode: .inline)
            .sheetCommitToolbar(onSave: {
                saveProfile()
                dismiss()
            })
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
        if let photoPath = store.myProfile?.photoPath, !photoPath.isEmpty {
            photoDraft = FoodStore.PhotosDraft(existingPaths: [photoPath])
        }
    }

    private func saveProfile() {
        let photoData = photoDraft.addedData.first
        let removePhoto = photoDraft.isEmpty && store.myProfile?.photoPath != nil
        Task {
            await store.updateProfile(
                firstName: firstName,
                lastName: lastName,
                newPhotoData: photoData,
                removePhoto: removePhoto
            )
        }
    }
}
