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
                        VStack(spacing: 0) {
                            Input(
                                label: "First name",
                                placeholder: "Required",
                                text: $firstName
                            )
                            .textContentType(.givenName)
                            .textInputAutocapitalization(.words)
                            .onSubmit { saveProfile() }

                            Divider()
                                .padding(.vertical, DS.Spacing.sm)

                            Input(
                                label: "Last name",
                                placeholder: "Required",
                                text: $lastName
                            )
                            .textContentType(.familyName)
                            .textInputAutocapitalization(.words)
                            .onSubmit { saveProfile() }
                        }
                    }

                    NotificationPreferencesSection()

                    AccountDangerSection(
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
