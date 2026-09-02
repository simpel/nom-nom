import SwiftUI
import PhotosUI

/// Photo picker and preview section for the meal editor form.
struct MealEditorPhotoSection: View {
    @Binding var pickedData: Data?
    @Binding var didRemovePhoto: Bool
    @Binding var pickerItem: PhotosPickerItem?
    @Binding var showCamera: Bool
    let existingPath: String?
    let loadingPhoto: Bool

    private var hasPhoto: Bool {
        if pickedData != nil { return true }
        return existingPath != nil && !didRemovePhoto
    }

    var body: some View {
        Section {
            VStack(spacing: 12) {
                photoPreview
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        if loadingPhoto { ProgressView() }
                    }

                HStack(spacing: 10) {
                    if CameraPicker.isAvailable {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Camera", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                        Label("Library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    if hasPhoto {
                        Button(role: .destructive) {
                            pickedData = nil
                            pickerItem = nil
                            didRemovePhoto = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var photoPreview: some View {
        if let pickedData {
            MealPhoto(data: pickedData, cornerRadius: AppRadius.photo)
        } else if let existingPath, !didRemovePhoto {
            RemoteMealPhoto(path: existingPath, cornerRadius: AppRadius.photo)
        } else {
            MealPhoto(data: nil, cornerRadius: AppRadius.photo)
        }
    }
}
