import SwiftUI

/// Dedicated sheet for editing personal profile information, photo avatar, notification preferences, and account actions.
struct ProfileSheetView: View {
    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var photoDraft = FoodStore.PhotosDraft()
    @State private var didLoadProfile = false

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

                    NameFieldsCard(
                        "Profile Details",
                        firstName: $firstName,
                        lastName: $lastName,
                        onSubmit: saveProfile
                    )

                    NotificationPreferencesSection()

                    AccountActionsSection(includesSignOut: false)
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
