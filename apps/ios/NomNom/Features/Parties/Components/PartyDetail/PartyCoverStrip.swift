import SwiftUI
import PhotosUI

/// The party's photos as a PhotoStrip above its DetailHeader, cover first. Tap
/// opens the viewer. Members get PhotoStrip's Add photo tile while the party has
/// fewer than `PhotosDraft.maxCount` photos; it asks camera or library (several
/// picks at once) and appends them. Non-members with no photos see nothing.
/// Reordering and removing photos stays in PartySettingsSheet.
struct PartyCoverStrip: View {
    let party: Party
    let onSelect: (Int) -> Void

    @Environment(FoodStore.self) private var store
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showSourceChoice = false
    @State private var showLibrary = false
    @State private var showCamera = false
    @State private var isUploading = false

    private var remaining: Int { FoodStore.PhotosDraft.maxCount - party.photoPaths.count }

    private var canAdd: Bool { remaining > 0 && store.isMember(of: party.id) }

    var body: some View {
        if !party.photoPaths.isEmpty || canAdd {
            PhotoStrip(
                photos: party.photoPaths.map { .remote(path: $0, bucket: SupabaseConfig.partyBucket) },
                format: .landscape,
                onAddPhoto: canAdd ? addPhoto : nil,
                onSelect: onSelect
            )
            .overlay {
                if isUploading {
                    ProgressView().controlSize(.regular)
                }
            }
            .disabled(isUploading)
            .confirmationDialog("Add photos", isPresented: $showSourceChoice) {
                Button("Take photo") { showCamera = true }
                Button("Choose from library") { showLibrary = true }
            }
            .photosPicker(
                isPresented: $showLibrary,
                selection: $pickerItems,
                maxSelectionCount: max(remaining, 1),
                selectionBehavior: .ordered,
                matching: .images,
                photoLibrary: .shared()
            )
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in
                    if let prepared = PhotoTools.prepare(image) {
                        Task { await upload([prepared]) }
                    }
                }
                .ignoresSafeArea()
            }
            .task(id: pickerItems) { await handlePickedPhotos() }
        }
    }

    private func addPhoto() {
        if CameraPicker.isAvailable {
            showSourceChoice = true
        } else {
            showLibrary = true
        }
    }

    private func handlePickedPhotos() async {
        guard !pickerItems.isEmpty else { return }
        let items = pickerItems
        pickerItems = []
        var photos: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let prepared = PhotoTools.prepare(data) {
                photos.append(prepared)
            }
        }
        await upload(photos)
    }

    private func upload(_ photos: [Data]) async {
        guard !photos.isEmpty else { return }
        isUploading = true
        await store.addPartyPhotos(photos, to: party)
        isUploading = false
    }
}
