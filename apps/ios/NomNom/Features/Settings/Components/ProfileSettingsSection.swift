import SwiftUI

/// Profile editing section in Settings: photo and name fields.
struct ProfileSettingsSection: View {
    @Environment(FoodStore.self) private var store

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var photoDraft = FoodStore.PhotosDraft()
    @State private var didLoadProfile = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.block) {
            AssetPhotosPickerSection(
                draft: $photoDraft,
                title: "Profile photo",
                bucket: SupabaseConfig.profileBucket,
                maxCount: 1
            )

            NameFieldsCard(
                "Profile details",
                firstName: $firstName,
                lastName: $lastName,
                placeholder: "Required",
                footnote: "This is the name other dinner party members see when you share meals and rate dishes.",
                onSubmit: saveProfile
            )
        }
        .onAppear(perform: loadProfileIfNeeded)
        .onChange(of: photoDraft) { _, _ in
            saveProfile()
        }
        .onDisappear(perform: saveProfile)
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
        guard didLoadProfile else { return }
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
