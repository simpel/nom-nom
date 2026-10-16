import SwiftUI

/// PhotoStrip's edit mode, for photo drafts in editors: PhotoCard `sm` tiles that
/// scroll sideways past the gutters, each with a remove button, a "Cover" (or page)
/// Badge, and Make cover / Move left / Move right in its context menu. Below the
/// strip, "Add photo" opens the Add photo sheet (camera or library, plus "Generate
/// with AI" when `onGenerate` is set) until `maxCount`. Empty, it shows PhotoStrip's
/// dashed "Add a photo" tile. `pendingAIPhoto` shows the AI photo still to be made.
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
    /// Offers "Generate with AI" in the Add photo sheet.
    var onGenerate: (() -> Void)?
    /// An AI photo will be made on save: shown first, tap to undo.
    var pendingAIPhoto: Binding<Bool>?

    @State private var showAddSheet = false

    init(
        items: [PhotoStripEditorItem],
        maxCount: Int,
        badge: PhotoStripEditorBadge = .cover,
        bleed: CGFloat = DS.Spacing.gutter,
        onAdd: (([Data]) -> Void)?,
        onRemove: @escaping (Int) -> Void,
        onMove: ((Int, Int) -> Void)? = nil,
        onSelect: @escaping (Int) -> Void,
        onGenerate: (() -> Void)? = nil,
        pendingAIPhoto: Binding<Bool>? = nil
    ) {
        self.items = items
        self.maxCount = maxCount
        self.badge = badge
        self.bleed = bleed
        self.onAdd = onAdd
        self.onRemove = onRemove
        self.onMove = onMove
        self.onSelect = onSelect
        self.onGenerate = onGenerate
        self.pendingAIPhoto = pendingAIPhoto
    }

    /// A single-photo slot replaces its photo, so it can always add.
    private var canAdd: Bool { onAdd != nil && (maxCount == 1 || items.count < maxCount) }
    private var pickLimit: Int { maxCount == 1 ? 1 : max(1, maxCount - items.count) }
    private var isPendingAI: Bool { pendingAIPhoto?.wrappedValue == true }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            if items.isEmpty && !isPendingAI {
                if canAdd {
                    PhotoStripAddTile(
                        title: "Add a photo",
                        offersAI: onGenerate != nil
                    ) { showAddSheet = true }
                }
            } else {
                strip
                if canAdd {
                    AppButton("Add photo", icon: "plus", variant: .secondary, appearance: .soft, size: .sm) {
                        showAddSheet = true
                    }
                }
            }
        }
        .addPhotoSheet(isPresented: $showAddSheet, maxCount: pickLimit, onGenerate: onGenerate) { onAdd?($0) }
    }

    private var strip: some View {
        // As PhotoStrip: never hide the scroll bar; touch gets the platform's own.
        ScrollView(.horizontal) {
            HStack(spacing: DS.Spacing.s2_5) {
                if isPendingAI {
                    PendingAIPhotoTile { pendingAIPhoto?.wrappedValue = false }
                }
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
            .scrollTargetLayout()
        }
        // `.nn-scroller`: snap to each tile, as PhotoStrip.
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, bleed, for: .scrollContent)
        .padding(.horizontal, -bleed)
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
