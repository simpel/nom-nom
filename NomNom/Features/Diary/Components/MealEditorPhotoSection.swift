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
                        AppButton(
                            "Camera",
                            systemImage: "camera.fill",
                            variant: .neutral,
                            style: .outlined,
                            size: .md,
                            isFullWidth: true
                        ) {
                            showCamera = true
                        }
                    }

                    PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.callout.weight(.semibold))
                            Text("Library")
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .padding(.horizontal, 16)
                        .foregroundStyle(DS.Color.textPrimary)
                        .background(Color.clear)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule().strokeBorder(DS.Color.lineStrong, lineWidth: 1.5)
                        }
                    }

                    if hasPhoto {
                        AppButton(
                            systemImage: "trash",
                            variant: .destructive,
                            style: .outlined,
                            size: .md
                        ) {
                            pickedData = nil
                            pickerItem = nil
                            didRemovePhoto = true
                        }
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
            if CameraPicker.isAvailable {
                Button {
                    showCamera = true
                } label: {
                    MealPhoto(data: nil, cornerRadius: AppRadius.photo)
                }
                .buttonStyle(.plain)
            } else {
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    MealPhoto(data: nil, cornerRadius: AppRadius.photo)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
