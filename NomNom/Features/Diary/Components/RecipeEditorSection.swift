import SwiftUI
import PhotosUI

/// Section in the meal editor for attaching or editing a recipe (instructions and/or photos).
struct RecipeEditorSection: View {
    @Binding var draft: FoodStore.RecipeDraft

    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var isLoadingPhotos = false
    @State private var previewIndex: Int?

    var body: some View {
        SectionCard("Instructions & Ingredients") {
            TextField("Ingredients, preparation steps, oven temp, notes...",
                      text: $draft.text,
                      axis: .vertical)
                .lineLimit(4...14)
                .textInputAutocapitalization(.sentences)
        }

        SectionCard("Recipe Photos") {
            photosEditor
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                if let prepared = PhotoTools.prepare(image) {
                    draft.addedPhotoData.append(prepared)
                }
            }
            .ignoresSafeArea()
        }
        .sheet(item: Binding(
            get: { previewIndex.map { PreviewWrapper(index: $0) } },
            set: { previewIndex = $0?.index }
        )) { item in
            RecipePhotoViewerSheet(draft: draft, initialIndex: item.index)
        }
        .task(id: selectedPickerItems) {
            await loadPickedPhotos()
        }
    }

    // MARK: - Subviews

    private var photosEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            let totalPhotos = draft.existingPhotoPaths.count + draft.addedPhotoData.count
            if totalPhotos > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Existing uploaded photos
                        ForEach(Array(draft.existingPhotoPaths.enumerated()), id: \.element) { index, path in
                            photoThumbnail(isExisting: true, index: index, path: path, data: nil)
                        }

                        // Newly added photo data
                        ForEach(Array(draft.addedPhotoData.enumerated()), id: \.offset) { offset, data in
                            let absoluteIndex = draft.existingPhotoPaths.count + offset
                            photoThumbnail(isExisting: false, index: absoluteIndex, path: nil, data: data)
                        }
                    }
                    .padding(.vertical, 4)
                }
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

                PhotosPicker(selection: $selectedPickerItems,
                             matching: .images,
                             photoLibrary: .shared()) {
                    Label(totalPhotos == 0 ? "Add Photos" : "Add More", systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                if isLoadingPhotos {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func photoThumbnail(isExisting: Bool, index: Int, path: String?, data: Data?) -> some View {
        ZStack(alignment: .topTrailing) {
            Button {
                previewIndex = index
            } label: {
                if let path {
                    RemoteMealPhoto(path: path, cornerRadius: AppRadius.photo, bucket: SupabaseConfig.recipeBucket)
                        .frame(width: 88, height: 110)
                } else if let data {
                    MealPhoto(data: data, cornerRadius: AppRadius.photo)
                        .frame(width: 88, height: 110)
                }
            }
            .buttonStyle(.plain)

            Button {
                if isExisting, let path {
                    draft.existingPhotoPaths.removeAll { $0 == path }
                    draft.removedPhotoPaths.append(path)
                } else if !isExisting {
                    let localOffset = index - draft.existingPhotoPaths.count
                    if draft.addedPhotoData.indices.contains(localOffset) {
                        draft.addedPhotoData.remove(at: localOffset)
                    }
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white, Color.black.opacity(0.6))
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func loadPickedPhotos() async {
        guard !selectedPickerItems.isEmpty else { return }
        isLoadingPhotos = true
        defer {
            isLoadingPhotos = false
            selectedPickerItems = []
        }

        for item in selectedPickerItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let prepared = PhotoTools.prepare(data) {
                draft.addedPhotoData.append(prepared)
            }
        }
    }
}

private struct PreviewWrapper: Identifiable {
    let index: Int
    var id: Int { index }
}
