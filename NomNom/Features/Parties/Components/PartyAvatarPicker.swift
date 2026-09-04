import SwiftUI
import PhotosUI

/// Interactive circular avatar picker used in party creation and settings sheets.
/// Allows selecting a new picture, previewing it, or removing an existing picture.
struct PartyAvatarPicker: View {
    let partyName: String
    var existingPhotoPath: String? = nil
    @Binding var photoData: Data?
    var isRemoved: Binding<Bool>? = nil
    var size: CGFloat = 80

    @State private var pickerItem: PhotosPickerItem?

    private var hasPhoto: Bool {
        if photoData != nil { return true }
        if let existing = existingPhotoPath, !existing.isEmpty, !(isRemoved?.wrappedValue ?? false) {
            return true
        }
        return false
    }

    var body: some View {
        VStack(spacing: 10) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    avatarPreview

                    // Camera badge overlay
                    Circle()
                        .fill(DS.Color.panel)
                        .frame(width: 26, height: 26)
                        .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DS.Color.accentText)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                        )
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Change party photo")

            HStack(spacing: 16) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Text(hasPhoto ? "Change Photo" : "Add Photo")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(DS.Color.accentText)
                }

                if hasPhoto {
                    Button(role: .destructive) {
                        photoData = nil
                        isRemoved?.wrappedValue = true
                    } label: {
                        Text("Remove")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: pickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let prepared = PhotoTools.prepare(data) {
                    photoData = prepared
                    isRemoved?.wrappedValue = false
                }
            }
        }
    }

    @ViewBuilder
    private var avatarPreview: some View {
        if let photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                )
        } else if let existing = existingPhotoPath, !existing.isEmpty, !(isRemoved?.wrappedValue ?? false) {
            PartyAvatar(name: partyName, photoPath: existing, size: size)
        } else {
            PartyAvatar(name: partyName, size: size)
        }
    }
}
