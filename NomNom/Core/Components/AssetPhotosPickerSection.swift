import SwiftUI
import PhotosUI
import UIKit

/// Multi-photo picker and hero card deck presentation with drag-to-reorder.
/// Used symmetrically across both Meals and Recipes for managing cover photos.
struct AssetPhotosPickerSection: View {
    @Binding var draft: FoodStore.PhotosDraft
    var title: String = "Photos"
    var caption: String? = "Optional"

    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var isLoadingPhotos = false
    @State private var previewIndex: Int?

    var body: some View {
        Group {
            if draft.count > 0 {
                populatedDeckView
            } else {
                emptyDeckView
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                guard draft.count < FoodStore.PhotosDraft.maxCount else { return }
                if let prepared = PhotoTools.prepare(image), !draft.contains(data: prepared) {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
                        draft.append(prepared)
                    }
                }
            }
            .ignoresSafeArea()
        }
        .sheet(item: Binding(
            get: { previewIndex.map { PhotoPreviewItem(index: $0) } },
            set: { previewIndex = $0?.index }
        )) { item in
            MealPhotoViewerSheet(draft: draft, initialIndex: item.index)
        }
        .task(id: selectedPickerItems) {
            await loadPickedPhotos()
        }
    }

    // MARK: - Empty State Hero Deck

    private var emptyDeckView: some View {
        VStack(spacing: DS.Spacing.md) {
            EmptyPhotoDeckHeroView(selectedPickerItems: $selectedPickerItems)
                .frame(height: 228)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

            if CameraPicker.isAvailable || isLoadingPhotos {
                emptyActionButtons
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 6)
    }

    private var emptyActionButtons: some View {
        HStack(spacing: 10) {
            if CameraPicker.isAvailable {
                Button {
                    showCamera = true
                } label: {
                    SubtleCapsuleLabel(title: "Camera", systemImage: "camera")
                }
                .buttonStyle(.plain)
            }

            if isLoadingPhotos {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    // MARK: - Populated Arc Deck

    private var populatedDeckView: some View {
        VStack(spacing: DS.Spacing.md) {
            MealPhotoDeckArcView(draft: $draft) { index in
                previewIndex = index
            }
            .frame(height: 228)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)

            populatedActionButtons
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 6)
    }

    private var populatedActionButtons: some View {
        HStack(spacing: 10) {
            if draft.count < FoodStore.PhotosDraft.maxCount {
                if CameraPicker.isAvailable {
                    Button {
                        showCamera = true
                    } label: {
                        SubtleCapsuleLabel(title: "Camera", systemImage: "camera")
                    }
                    .buttonStyle(.plain)
                }

                PhotosPicker(selection: $selectedPickerItems,
                             maxSelectionCount: FoodStore.PhotosDraft.maxCount - draft.count,
                             matching: .images,
                             photoLibrary: .shared()) {
                    SubtleCapsuleLabel(title: "Add more", systemImage: "plus")
                }
                .buttonStyle(.plain)
            }

            if isLoadingPhotos {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private func loadPickedPhotos() async {
        guard !selectedPickerItems.isEmpty else { return }
        isLoadingPhotos = true
        defer {
            isLoadingPhotos = false
            selectedPickerItems = []
        }

        var loaded: [Data] = []
        for item in selectedPickerItems {
            guard (draft.count + loaded.count) < FoodStore.PhotosDraft.maxCount else { break }
            if let data = try? await item.loadTransferable(type: Data.self),
               let prepared = PhotoTools.prepare(data) {
                if !loaded.contains(prepared) && !draft.contains(data: prepared) {
                    loaded.append(prepared)
                }
            }
        }

        guard !loaded.isEmpty else { return }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
            for data in loaded {
                draft.append(data)
            }
        }
    }
}

private struct PhotoPreviewItem: Identifiable {
    let index: Int
    var id: Int { index }
}
