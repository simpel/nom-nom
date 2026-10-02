import SwiftUI
import PhotosUI

/// One-photo picker and preview for the meal editor: a PhotoCard `lg` landscape
/// filling the width (the no-photo tile opens the camera or library), then Camera,
/// Library and remove buttons.
///
/// No caller yet: the meal editor uses `MealPhotosPickerSection` (PhotoStripEditor).
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

    private var source: PhotoCardSource {
        if let pickedData { return .data(pickedData) }
        if let existingPath, !didRemovePhoto { return .remote(path: existingPath) }
        return .none()
    }

    var body: some View {
        VStack(spacing: DS.Spacing.s3) {
            photoPreview
                .overlay {
                    if loadingPhoto { ProgressView() }
                }

            HStack(spacing: DS.Spacing.s2_5) {
                if CameraPicker.isAvailable {
                    AppButton("Camera", icon: "camera.fill", variant: .secondary, appearance: .outline, fullWidth: true) {
                        showCamera = true
                    }
                }

                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    AppButtonLabel("Library", icon: "photo.on.rectangle", variant: .secondary, appearance: .outline, fullWidth: true)
                }
                .buttonStyle(AppPressableButtonStyle())

                if hasPhoto {
                    AppButton(icon: "trash", accessibilityLabel: "Remove photo", variant: .destructive, appearance: .outline) {
                        pickedData = nil
                        pickerItem = nil
                        didRemovePhoto = true
                    }
                }
            }
        }
    }

    private var card: some View {
        PhotoCard(source, size: .lg, format: .landscape, fillsWidth: true)
    }

    @ViewBuilder
    private var photoPreview: some View {
        if hasPhoto {
            card
        } else if CameraPicker.isAvailable {
            Button {
                showCamera = true
            } label: {
                card
            }
            .buttonStyle(AppPressableButtonStyle())
        } else {
            PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                card
            }
            .buttonStyle(AppPressableButtonStyle())
        }
    }
}
