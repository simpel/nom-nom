import SwiftUI
import PhotosUI
import UIKit

/// Multi-photo picker and hero card deck presentation with drag-to-reorder.
/// Used symmetrically across both Meals and Recipes for managing cover photos.
struct AssetPhotosPickerSection: View {
    @Binding var draft: FoodStore.PhotosDraft
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var isLoadingPhotos = false
    @State private var previewIndex: Int?

    var body: some View {
        Section {
            VStack(spacing: DS.Spacing.md) {
                ZStack {
                    if draft.count > 0 {
                        MealPhotoDeckArcView(draft: $draft) { index in
                            previewIndex = index
                        }
                        .transition(.opacity)
                    } else {
                        emptyDeckHero
                            .transition(.opacity)
                    }
                }
                .frame(height: 228)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

                ZStack {
                    if draft.count > 0 {
                        Text(deckSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .transition(.opacity)
                    }
                }
                .frame(height: 18)

                actionButtons
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 6)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowSeparator(.hidden)
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                if let prepared = PhotoTools.prepare(image) {
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

    private var emptyDeckHero: some View {
        PhotosPicker(selection: $selectedPickerItems, matching: .images, photoLibrary: .shared()) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                    .fill(Color.accentColor.opacity(0.04))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1.5)
                    }
                    .frame(width: 144, height: 192)
                    .rotationEffect(.degrees(-7))
                    .offset(x: -22, y: 4)

                RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                    .fill(DS.Color.sunken)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                            .strokeBorder(DS.Color.line, lineWidth: 1.5)
                    }
                    .frame(width: 144, height: 192)
                    .rotationEffect(.degrees(7))
                    .offset(x: 22, y: 4)

                RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                    .fill(DS.Color.panel)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                            .strokeBorder(DS.Color.lineStrong, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    }
                    .overlay {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(DS.Color.accentSoft)
                                    .frame(width: 52, height: 52)
                                Image(systemName: "camera.badge.ellipsis")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundStyle(DS.Color.accentText)
                            }

                            Text("Add Photos")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(DS.Color.textPrimary)

                            Text("Tap to choose")
                                .font(.caption2)
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                        .padding(12)
                    }
                    .frame(width: 144, height: 192)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            }
            .frame(height: 220)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            if CameraPicker.isAvailable {
                Button {
                    showCamera = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Camera")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            }

            PhotosPicker(selection: $selectedPickerItems,
                         matching: .images,
                         photoLibrary: .shared()) {
                HStack(spacing: 6) {
                    Image(systemName: draft.count == 0 ? "photo.stack.fill" : "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text(draft.count == 0 ? "Photo Library" : "Add More")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)

            if isLoadingPhotos {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var deckSubtitle: String {
        let count = draft.count
        if count == 1 {
            return "1 photo • Tap to preview"
        } else {
            return "\(count) photos • Drag left/right to reorder • First is cover"
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
            if let data = try? await item.loadTransferable(type: Data.self),
               let prepared = PhotoTools.prepare(data) {
                loaded.append(prepared)
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
