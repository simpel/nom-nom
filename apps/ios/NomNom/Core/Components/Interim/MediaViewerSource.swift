// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import Foundation

/// What a MediaViewerSheet pages through.
enum MediaViewerSource {
    /// Stored photos in one bucket.
    case paths([String], bucket: String = SupabaseConfig.photoBucket)
    /// A meal/cover photo draft: stored photos and fresh picks, in draft order.
    case photosDraft(FoodStore.PhotosDraft, bucket: String = SupabaseConfig.photoBucket)
    /// A recipe draft's page photos: stored pages (recipe bucket), then fresh picks.
    case recipeDraft(FoodStore.RecipeDraft)

    /// The pages in display order.
    var pages: [MediaViewerPageSource] {
        switch self {
        case .paths(let paths, let bucket):
            return paths.map { .remote(path: $0, bucket: bucket) }
        case .photosDraft(let draft, let bucket):
            return draft.items.map { item in
                switch item {
                case .existing(let path): return .remote(path: path, bucket: bucket)
                case .added(let id, let data): return .data(id: id.uuidString, data: data)
                }
            }
        case .recipeDraft(let draft):
            let stored = draft.existingPhotoPaths.map {
                MediaViewerPageSource.remote(path: $0, bucket: SupabaseConfig.recipeBucket)
            }
            let added = draft.addedPhotoData.enumerated().map {
                MediaViewerPageSource.data(id: "added-\($0.offset)", data: $0.element)
            }
            return stored + added
        }
    }
}

/// One page of a MediaViewerSheet.
enum MediaViewerPageSource: Identifiable, Equatable {
    case remote(path: String, bucket: String)
    case data(id: String, data: Data)

    var id: String {
        switch self {
        case .remote(let path, let bucket): return "\(bucket):\(path)"
        case .data(let id, _): return "data:\(id)"
        }
    }
}
