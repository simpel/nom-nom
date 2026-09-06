import SwiftUI
import PhotosUI
import UIKit

/// Multi-photo picker and hero card deck presentation with drag-to-reorder.
/// Used symmetrically across both Meals and Recipes for managing cover photos.
struct AssetPhotosPickerSection: View {
    @Binding var draft: FoodStore.PhotosDraft
    var title: String = "Photos"
    var caption: String? = "Optional"
    var bucket: String = SupabaseConfig.photoBucket
    var maxCount: Int = FoodStore.PhotosDraft.maxCount

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
                if maxCount == 1 {
                    if let prepared = PhotoTools.prepare(image) {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
                            draft.items = [.added(id: UUID(), data: prepared)]
                        }
                    }
                } else {
                    guard draft.count < maxCount else { return }
                    if let prepared = PhotoTools.prepare(image), !draft.contains(data: prepared) {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
                            draft.append(prepared)
                        }
                    }
                }
            }
            .ignoresSafeArea()
        }
        .sheet(item: Binding(
            get: { previewIndex.map { PhotoPreviewItem(index: $0) } },
            set: { previewIndex = $0?.index }
        )) { item in
            MealPhotoViewerSheet(draft: draft, initialIndex: item.index, bucket: bucket)
        }
        .task(id: selectedPickerItems) {
            await loadPickedPhotos()
        }
    }

    // MARK: - Empty State Hero Deck

    private var deckTitle: String {
        if title.hasPrefix("Add ") {
            return title
        }
        return "Add \(title)"
    }

    private var emptyDeckView: some View {
        VStack(spacing: DS.Spacing.md) {
            EmptyPhotoDeckHeroView(
                selectedPickerItems: $selectedPickerItems,
                title: deckTitle,
                maxSelectionCount: maxCount,
                onDeckTap: { showCamera = true }
            )
            .frame(height: 228)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)

            emptyActionButtons
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

            PhotosPicker(selection: $selectedPickerItems,
                         maxSelectionCount: maxCount,
                         matching: .images,
                         photoLibrary: .shared()) {
                SubtleCapsuleLabel(title: "Library", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.plain)

            if isLoadingPhotos {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    // MARK: - Populated Arc Deck

    private var populatedDeckView: some View {
        VStack(spacing: DS.Spacing.md) {
            MealPhotoDeckArcView(draft: $draft, bucket: bucket) { index in
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
            if maxCount == 1 {
                if CameraPicker.isAvailable {
                    Button {
                        showCamera = true
                    } label: {
                        SubtleCapsuleLabel(title: "Camera", systemImage: "camera")
                    }
                    .buttonStyle(.plain)
                }

                PhotosPicker(selection: $selectedPickerItems,
                             maxSelectionCount: 1,
                             matching: .images,
                             photoLibrary: .shared()) {
                    SubtleCapsuleLabel(title: "Library", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.plain)
            } else if draft.count < maxCount {
                if CameraPicker.isAvailable {
                    Button {
                        showCamera = true
                    } label: {
                        SubtleCapsuleLabel(title: "Add photo", systemImage: "camera")
                    }
                    .buttonStyle(.plain)
                }

                PhotosPicker(selection: $selectedPickerItems,
                             maxSelectionCount: maxCount - draft.count,
                             matching: .images,
                             photoLibrary: .shared()) {
                    SubtleCapsuleLabel(title: "Library", systemImage: "photo.on.rectangle")
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

        if maxCount == 1 {
            if let item = selectedPickerItems.first,
               let data = try? await item.loadTransferable(type: Data.self),
               let prepared = PhotoTools.prepare(data) {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
                    draft.items = [.added(id: UUID(), data: prepared)]
                }
            }
            return
        }

        var loaded: [Data] = []
        for item in selectedPickerItems {
            guard (draft.count + loaded.count) < maxCount else { break }
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
