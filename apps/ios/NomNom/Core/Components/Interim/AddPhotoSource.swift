// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI
import PhotosUI

/// Presents AddPhotoSheet and runs what was picked once it has closed: the camera,
/// Photos (up to `maxCount`), or `onGenerate`. "Generate with AI" needs Pro: without it
/// the tap opens the paywall instead. Picks go through `PhotoTools.prepare`, as in
/// PhotoStripEditor, and arrive as JPEG data.
private struct AddPhotoSource: ViewModifier {
    @Binding var isPresented: Bool
    let maxCount: Int
    let onGenerate: (() -> Void)?
    let onPick: ([Data]) -> Void

    @Environment(EntitlementStore.self) private var entitlements
    @State private var choice: AddPhotoChoice?
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var showPaywall = false
    @State private var pickerItems: [PhotosPickerItem] = []

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, onDismiss: runChoice) {
                AddPhotoSheet(offersGenerate: onGenerate != nil) { choice = $0 }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in
                    if let prepared = PhotoTools.prepare(image) { onPick([prepared]) }
                }
                .ignoresSafeArea()
            }
            .photosPicker(isPresented: $showLibrary, selection: $pickerItems, maxSelectionCount: max(1, maxCount),
                          matching: .images, photoLibrary: .shared())
            .task(id: pickerItems) { await loadPicked() }
            .proPaywall(isPresented: $showPaywall)
    }

    private func runChoice() {
        defer { choice = nil }
        switch choice {
        case .generate:
            if entitlements.hasProAccess { onGenerate?() } else { showPaywall = true }
        case .camera:
            showCamera = true
        case .library:
            showLibrary = true
        case nil:
            break
        }
    }

    private func loadPicked() async {
        guard !pickerItems.isEmpty else { return }
        defer { pickerItems = [] }
        var loaded: [Data] = []
        for item in pickerItems.prefix(max(1, maxCount)) {
            if let data = try? await item.loadTransferable(type: Data.self),
               let prepared = PhotoTools.prepare(data),
               !loaded.contains(prepared) {
                loaded.append(prepared)
            }
        }
        if !loaded.isEmpty { onPick(loaded) }
    }
}

extension View {
    /// The Add photo sheet: "Generate with AI" (when `onGenerate` is set), "Take photo"
    /// and "Choose from library", opened when `isPresented` turns true.
    func addPhotoSheet(
        isPresented: Binding<Bool>,
        maxCount: Int = 1,
        onGenerate: (() -> Void)? = nil,
        onPick: @escaping ([Data]) -> Void
    ) -> some View {
        modifier(AddPhotoSource(isPresented: isPresented, maxCount: maxCount, onGenerate: onGenerate, onPick: onPick))
    }
}
