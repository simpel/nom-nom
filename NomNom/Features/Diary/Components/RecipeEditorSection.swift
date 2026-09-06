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
        RecipeIngredientsEditorSection(ingredients: $draft.ingredients)

        RecipeInstructionsEditorSection(instructions: $draft.instructions)

        SectionCard("Recipe Photos") {
            photosEditor
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                if let prepared = PhotoTools.prepare(image) {
                    draft.addPhotoData(prepared)
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

            if totalPhotos < 5 {
                HStack(spacing: 10) {
                    if CameraPicker.isAvailable {
                        AppButton(
                            totalPhotos == 0 ? "Add Photo" : "Camera",
                            systemImage: "camera",
                            variant: .neutral,
                            style: .outlined,
                            size: .sm,
                            isFullWidth: true
                        ) {
                            showCamera = true
                        }
                    }

                    PhotosPicker(selection: $selectedPickerItems,
                                 maxSelectionCount: 5 - totalPhotos,
                                 matching: .images,
                                 photoLibrary: .shared()) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.subheadline.weight(.semibold))
                            Text("Library")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .padding(.horizontal, 12)
                        .foregroundStyle(DS.Color.textPrimary)
                        .background(Color.clear)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule().strokeBorder(DS.Color.lineStrong, lineWidth: 1.5)
                        }
                    }

                    if isLoadingPhotos {
                        ProgressView()
                            .controlSize(.small)
                    }
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
            guard draft.canAddPhoto else { break }
            if let data = try? await item.loadTransferable(type: Data.self),
               let prepared = PhotoTools.prepare(data) {
                draft.addPhotoData(prepared)
            }
        }
    }
}

private struct PreviewWrapper: Identifiable {
    let index: Int
    var id: Int { index }
}
