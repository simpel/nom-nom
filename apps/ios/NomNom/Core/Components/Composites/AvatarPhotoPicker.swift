// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI
import PhotosUI

/// The photo source for one avatar (ScreenHeader's avatar edit mode): the native front
/// camera, with a library button over it that swaps to Photos. Without a camera (the
/// simulator) it opens Photos directly. Picks go through `PhotoTools.prepare`, as in
/// PhotoStripEditor, and arrive as JPEG data.
private struct AvatarPhotoPicker: ViewModifier {
    @Binding var isPresented: Bool
    let onPick: (Data) -> Void

    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var libraryAfterCamera = false
    @State private var pickerItem: PhotosPickerItem?

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, presented in
                guard presented else { return }
                isPresented = false
                if CameraPicker.isAvailable { showCamera = true } else { showLibrary = true }
            }
            .fullScreenCover(isPresented: $showCamera, onDismiss: {
                if libraryAfterCamera {
                    libraryAfterCamera = false
                    showLibrary = true
                }
            }) {
                CameraPicker(device: .front, onLibrary: { libraryAfterCamera = true }) { image in
                    if let prepared = PhotoTools.prepare(image) { onPick(prepared) }
                }
                .ignoresSafeArea()
            }
            .photosPicker(isPresented: $showLibrary, selection: $pickerItem, matching: .images, photoLibrary: .shared())
            .task(id: pickerItem) { await loadPicked() }
    }

    private func loadPicked() async {
        guard let item = pickerItem else { return }
        defer { pickerItem = nil }
        if let data = try? await item.loadTransferable(type: Data.self),
           let prepared = PhotoTools.prepare(data) {
            onPick(prepared)
        }
    }
}

extension View {
    /// Opens the camera (or Photos, without a camera) when `isPresented` turns true.
    func avatarPhotoPicker(isPresented: Binding<Bool>, onPick: @escaping (Data) -> Void) -> some View {
        modifier(AvatarPhotoPicker(isPresented: isPresented, onPick: onPick))
    }
}
