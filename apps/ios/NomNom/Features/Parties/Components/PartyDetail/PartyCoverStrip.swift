import SwiftUI
import PhotosUI

/// The party's cover photo as a PhotoStrip above its DetailHeader. Tap opens the
/// viewer. With no cover, members get PhotoStrip's "Add a photo" tile, which asks
/// camera or library and uploads the pick as the cover; non-members see nothing.
/// Replacing an existing cover stays in PartySettingsSheet.
struct PartyCoverStrip: View {
    let party: Party
    let onSelect: (Int) -> Void

    @Environment(FoodStore.self) private var store
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showSourceChoice = false
    @State private var showLibrary = false
    @State private var showCamera = false
    @State private var isUploading = false

    private var coverPath: String? {
        guard let path = party.photoPath, !path.isEmpty else { return nil }
        return path
    }

    private var canAdd: Bool { coverPath == nil && store.isMember(of: party.id) }

    var body: some View {
        if coverPath != nil || canAdd {
            PhotoStrip(
                photos: coverPath.map { [.remote(path: $0, bucket: SupabaseConfig.partyBucket)] } ?? [],
                onAddPhoto: canAdd ? addPhoto : nil,
                onSelect: onSelect
            )
            .overlay {
                if isUploading {
                    ProgressView().controlSize(.regular)
                }
            }
            .disabled(isUploading)
            .confirmationDialog("Add a cover photo", isPresented: $showSourceChoice) {
                Button("Take photo") { showCamera = true }
                Button("Choose from library") { showLibrary = true }
            }
            .photosPicker(isPresented: $showLibrary, selection: $pickerItems, maxSelectionCount: 1, matching: .images, photoLibrary: .shared())
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in
                    if let prepared = PhotoTools.prepare(image) {
                        Task { await upload(prepared) }
                    }
                }
                .ignoresSafeArea()
            }
            .task(id: pickerItems) { await handlePickedPhoto() }
        }
    }

    private func addPhoto() {
        if CameraPicker.isAvailable {
            showSourceChoice = true
        } else {
            showLibrary = true
        }
    }

    private func handlePickedPhoto() async {
        guard let item = pickerItems.first else { return }
        defer { pickerItems = [] }
        if let data = try? await item.loadTransferable(type: Data.self),
           let prepared = PhotoTools.prepare(data) {
            await upload(prepared)
        }
    }

    private func upload(_ data: Data) async {
        isUploading = true
        await store.updateParty(party, newPhotoData: data)
        isUploading = false
    }
}
