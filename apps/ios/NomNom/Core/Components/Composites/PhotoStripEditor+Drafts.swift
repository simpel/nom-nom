// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

// PhotoStripEditor bound to the app's photo draft models.

/// Tiles moving or resizing: `duration-layout` ease-out (tokens.json: "Every transition
/// in the system uses one of these"). Replaces an invented 0.42s spring.
private let photoDraftAnimation = DS.Motion.layout

extension PhotoStripEditor {
    /// A meal, cover or avatar photo set (`PhotosDraft`): add, remove and reorder.
    /// `maxCount: 1` replaces the photo instead of adding (avatars, party covers),
    /// and hides the "Cover" badge.
    init(
        draft: Binding<FoodStore.PhotosDraft>,
        bucket: String = SupabaseConfig.photoBucket,
        maxCount: Int = FoodStore.PhotosDraft.maxCount,
        onSelect: @escaping (Int) -> Void
    ) {
        let items = draft.wrappedValue.items.map { item -> PhotoStripEditorItem in
            switch item {
            case .existing(let path):
                return PhotoStripEditorItem(id: item.id, source: .remote(path: path, bucket: bucket))
            case .added(_, let data):
                return PhotoStripEditorItem(id: item.id, source: .data(data))
            }
        }
        self.init(
            items: items,
            maxCount: maxCount,
            badge: maxCount > 1 ? .cover : .none,
            onAdd: { photos in
                withAnimation(photoDraftAnimation) {
                    if maxCount == 1, let first = photos.first {
                        draft.wrappedValue.items = [.added(id: UUID(), data: first)]
                    } else {
                        for data in photos where draft.wrappedValue.count < maxCount {
                            draft.wrappedValue.append(data)
                        }
                    }
                }
            },
            onRemove: { index in
                withAnimation(photoDraftAnimation) { draft.wrappedValue.remove(at: index) }
            },
            onMove: maxCount > 1 ? { from, to in
                withAnimation(photoDraftAnimation) {
                    draft.wrappedValue.move(from: IndexSet(integer: from), to: to > from ? to + 1 : to)
                }
            } : nil,
            onSelect: onSelect
        )
    }

    /// A recipe's page photos (`RecipeDraft`): add and remove, in page order.
    /// Not reorderable: the draft keeps stored and new pages in separate lists.
    init(
        recipeDraft: Binding<FoodStore.RecipeDraft>,
        onSelect: @escaping (Int) -> Void
    ) {
        let draft = recipeDraft.wrappedValue
        let stored = draft.existingPhotoPaths.map {
            PhotoStripEditorItem(id: "existing:\($0)", source: .remote(path: $0, bucket: SupabaseConfig.recipeBucket))
        }
        let added = draft.addedPhotoData.enumerated().map {
            PhotoStripEditorItem(id: "added:\($0.offset):\($0.element.hashValue)", source: .data($0.element))
        }
        self.init(
            items: stored + added,
            maxCount: FoodStore.RecipeDraft.maxCount,
            badge: .pageNumber,
            onAdd: { photos in
                for data in photos { recipeDraft.wrappedValue.addPhotoData(data) }
            },
            onRemove: { index in
                let storedCount = recipeDraft.wrappedValue.existingPhotoPaths.count
                if index < storedCount {
                    let path = recipeDraft.wrappedValue.existingPhotoPaths.remove(at: index)
                    recipeDraft.wrappedValue.removedPhotoPaths.append(path)
                } else if recipeDraft.wrappedValue.addedPhotoData.indices.contains(index - storedCount) {
                    recipeDraft.wrappedValue.addedPhotoData.remove(at: index - storedCount)
                }
            },
            onSelect: onSelect
        )
    }

    /// Plain in-memory photos (scanned pages): remove only; adding is the caller's.
    init(
        photos: [Data],
        maxCount: Int,
        onRemove: @escaping (Int) -> Void,
        onSelect: @escaping (Int) -> Void
    ) {
        self.init(
            items: photos.enumerated().map {
                PhotoStripEditorItem(id: "\($0.offset):\($0.element.hashValue)", source: .data($0.element))
            },
            maxCount: maxCount,
            badge: .pageNumber,
            onAdd: nil,
            onRemove: onRemove,
            onSelect: onSelect
        )
    }
}
