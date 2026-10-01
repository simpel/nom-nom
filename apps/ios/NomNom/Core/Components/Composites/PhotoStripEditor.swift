// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI
import PhotosUI

/// PhotoStrip's edit mode, for photo drafts in editors: PhotoCard `sm` tiles that
/// scroll sideways past the gutters, each with a remove button, a "Cover" (or page)
/// Badge, and Make cover / Move left / Move right in its context menu. Below the
/// strip, "Camera" (AppButton) and "Library" (a PhotosPicker with an AppButtonLabel)
/// add photos until `maxCount`. Empty, it shows PhotoStrip's dashed "Add a photo" tile.
///
/// Model-agnostic: pass the items and callbacks, or use a draft adapter from
/// `PhotoStripEditor+Drafts.swift`. Omit `onAdd` for a strip that only removes.
struct PhotoStripEditor: View {
    let items: [PhotoStripEditorItem]
    var maxCount: Int
    var badge: PhotoStripEditorBadge
    var bleed: CGFloat
    /// Receives prepared (downscaled JPEG) photos; nil hides the add controls.
    var onAdd: (([Data]) -> Void)?
    var onRemove: (Int) -> Void
    /// (from, to); nil disables reordering.
    var onMove: ((Int, Int) -> Void)?
    var onSelect: (Int) -> Void

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var showSourceChoice = false
    @State private var showLibrary = false
    @State private var isLoading = false

    init(
        items: [PhotoStripEditorItem],
        maxCount: Int,
        badge: PhotoStripEditorBadge = .cover,
        bleed: CGFloat = DS.Spacing.gutter,
        onAdd: (([Data]) -> Void)?,
        onRemove: @escaping (Int) -> Void,
        onMove: ((Int, Int) -> Void)? = nil,
        onSelect: @escaping (Int) -> Void
    ) {
        self.items = items
        self.maxCount = maxCount
        self.badge = badge
        self.bleed = bleed
        self.onAdd = onAdd
        self.onRemove = onRemove
        self.onMove = onMove
        self.onSelect = onSelect
    }

    /// A single-photo slot replaces its photo, so it can always add.
    private var canAdd: Bool { onAdd != nil && (maxCount == 1 || items.count < maxCount) }
    private var pickLimit: Int { maxCount == 1 ? 1 : max(1, maxCount - items.count) }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            if items.isEmpty {
                if canAdd {
                    PhotoStripEmptyAddTile {
                        if CameraPicker.isAvailable { showSourceChoice = true } else { showLibrary = true }
                    }
                }
            } else {
                strip
                if canAdd { addButtons }
            }
        }
        .confirmationDialog("Add a photo", isPresented: $showSourceChoice) {
            Button("Take photo") { showCamera = true }
            Button("Choose from library") { showLibrary = true }
        }
        .photosPicker(isPresented: $showLibrary, selection: $pickerItems, maxSelectionCount: pickLimit, matching: .images, photoLibrary: .shared())
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                if let prepared = PhotoTools.prepare(image) { onAdd?([prepared]) }
            }
            .ignoresSafeArea()
        }
        .task(id: pickerItems) { await loadPicked() }
    }

    private var strip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.s2_5) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    PhotoStripEditorTile(
                        item: item,
                        index: index,
                        count: items.count,
                        badgeText: badge.text(at: index),
                        showsMakeCover: badge == .cover,
                        onSelect: { onSelect(index) },
                        onRemove: { onRemove(index) },
                        onMove: onMove.map { move in { target in move(index, target) } }
                    )
                }
            }
        }
        .contentMargins(.horizontal, bleed, for: .scrollContent)
        .padding(.horizontal, -bleed)
    }

    private var addButtons: some View {
        HStack(spacing: DS.Spacing.s2) {
            if CameraPicker.isAvailable {
                AppButton("Camera", icon: "camera", variant: .secondary, appearance: .soft, size: .sm) {
                    showCamera = true
                }
            }
            PhotosPicker(selection: $pickerItems, maxSelectionCount: pickLimit, matching: .images, photoLibrary: .shared()) {
                AppButtonLabel("Library", icon: "photo.on.rectangle", variant: .secondary, appearance: .soft, size: .sm)
            }
            .buttonStyle(AppPressableButtonStyle())
            if isLoading {
                ProgressView().controlSize(.small)
            }
        }
    }

    private func loadPicked() async {
        guard !pickerItems.isEmpty else { return }
        isLoading = true
        defer {
            isLoading = false
            pickerItems = []
        }
        var loaded: [Data] = []
        for item in pickerItems.prefix(pickLimit) {
            if let data = try? await item.loadTransferable(type: Data.self),
               let prepared = PhotoTools.prepare(data),
               !loaded.contains(prepared) {
                loaded.append(prepared)
            }
        }
        if !loaded.isEmpty { onAdd?(loaded) }
    }
}

private struct PhotoStripEditorPreview: View {
    @State private var draft = FoodStore.PhotosDraft(existingPaths: ["a.jpg", "b.jpg", "c.jpg"])
    @State private var empty = FoodStore.PhotosDraft()

    var body: some View {
        NomNomPreview(inNavigationStack: false) { _ in
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.block) {
                    PhotoStripEditor(draft: $draft, onSelect: { _ in })
                    PhotoStripEditor(draft: $empty, onSelect: { _ in })
                }
                .padding(DS.Spacing.gutter)
            }
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { PhotoStripEditorPreview() }
#Preview("Dark") { PhotoStripEditorPreview().preferredColorScheme(.dark) }
