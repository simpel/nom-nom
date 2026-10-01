import SwiftUI
import UIKit

/// Where a PhotoCard's picture comes from. Every case runs the one fallback chain:
/// photo → cuisine category photo → the `sunken` no-photo tile.
enum PhotoCardSource {
    /// Stored photos; the first is shown. `cuisine` picks the category fallback.
    case remote(paths: [String], bucket: String = SupabaseConfig.photoBucket, cuisine: String? = nil)
    /// A picture already in memory (a fresh capture or a draft).
    case image(UIImage)
    /// Raw image bytes (a PhotosPicker draft); nil falls back to the cuisine photo.
    case data(Data?, cuisine: String? = nil)
    /// A recipe: its meal photos, then its recipe photos, then its cuisine (RecipeImageView's order).
    case recipe(Recipe)
    /// A meal: its first photo, then its dish's cuisine.
    case meal(Meal)
    /// No photo: the cuisine photo when one exists, else the no-photo tile.
    case none(cuisine: String? = nil)

    /// One stored photo.
    static func remote(path: String?, bucket: String = SupabaseConfig.photoBucket, cuisine: String? = nil) -> PhotoCardSource {
        .remote(paths: path.map { [$0] } ?? [], bucket: bucket, cuisine: cuisine)
    }

    /// The source with everything a PhotoCard needs looked up.
    @MainActor
    func resolved(in store: FoodStore?) -> PhotoCardResolvedSource {
        switch self {
        case .remote(let paths, let bucket, let cuisine):
            return PhotoCardResolvedSource(path: paths.first, bucket: bucket, cuisine: cuisine)
        case .image(let image):
            return PhotoCardResolvedSource(image: image)
        case .data(let data, let cuisine):
            return PhotoCardResolvedSource(image: data.flatMap(UIImage.init(data:)), cuisine: cuisine)
        case .recipe(let recipe):
            let paths = store?.photos(for: recipe) ?? []
            let path = paths.first ?? recipe.photoPaths.first ?? recipe.recipePhotoPaths.first
            let inRecipeBucket = path.map { recipe.photoPaths.contains($0) || recipe.recipePhotoPaths.contains($0) } ?? false
            return PhotoCardResolvedSource(
                path: path,
                bucket: inRecipeBucket ? SupabaseConfig.recipeBucket : SupabaseConfig.photoBucket,
                cuisine: recipe.cuisine
            )
        case .meal(let meal):
            return PhotoCardResolvedSource(
                path: meal.photoPaths.first,
                bucket: SupabaseConfig.photoBucket,
                cuisine: store?.dish(meal.dishID)?.cuisine
            )
        case .none(let cuisine):
            return PhotoCardResolvedSource(cuisine: cuisine)
        }
    }
}

/// A PhotoCardSource after lookup: an in-memory image, or a stored path, plus the cuisine fallback.
struct PhotoCardResolvedSource: Equatable {
    var image: UIImage?
    var path: String?
    var bucket: String = SupabaseConfig.photoBucket
    var cuisine: String?

    /// The cuisine category asset, when the cuisine has one.
    var cuisineAsset: String? { Cuisine.assetImageName(for: cuisine) }

    /// Identity for the photo loader.
    var loadKey: String? { path.map { "\(bucket):\($0)" } }
}

/// What a PhotoCard shows in its bottom-right corner.
enum PhotoCardBadge {
    /// A normalised 0–1 score, shown as its verdict word.
    case score(Double)
    /// A reaction step, shown as its verdict word.
    case reaction(Reaction)
    /// Any Badge; it is laid out as is (pass `appearance: .elevated, size: .sm`).
    case custom(Badge)

    var badge: Badge {
        switch self {
        case .score(let score): return .verdict(score: score, appearance: .elevated, size: .sm)
        case .reaction(let reaction): return .verdict(reaction, appearance: .elevated, size: .sm)
        case .custom(let badge): return badge
        }
    }
}

/// PhotoCard tiles: frame, corner radius and badge inset.
enum PhotoCardSize: Equatable, CaseIterable {
    /// `s20` square, `radius-xl`, no badge: RecipeLinkCard and row thumbnails.
    case xs
    /// `s36` × `s48` (3:4), `radius-2xl`: Timeline.
    case sm
    /// `s48` square, `radius-2xl`: RecipeCard (or fills its column at 1:1).
    case md
    /// `s64` × `s72`, `radius-3xl`: PhotoStrip.
    case lg

    var width: CGFloat {
        switch self {
        case .xs: return DS.Spacing.s20
        case .sm: return DS.Spacing.s36
        case .md: return DS.Spacing.s48
        case .lg: return DS.Spacing.s64
        }
    }

    var height: CGFloat {
        switch self {
        case .xs: return DS.Spacing.s20
        case .sm: return DS.Spacing.s48
        case .md: return DS.Spacing.s48
        case .lg: return DS.Spacing.s72
        }
    }

    var aspectRatio: CGFloat { width / height }

    var radius: CGFloat {
        switch self {
        case .xs: return DS.Radius.xl
        case .sm, .md: return DS.Radius.xl2
        case .lg: return DS.Radius.xl3
        }
    }

    var badgeInset: CGFloat { self == .lg ? DS.Spacing.s3 : DS.Spacing.s2 }
    var showsBadge: Bool { self != .xs }
    var showsCaption: Bool { self == .sm || self == .lg }

    /// Fork-and-knife glyph step on the no-photo tile.
    var glyphStyle: DS.TextStyle {
        switch self {
        case .xs: return .sansMd
        case .sm: return .sansLg
        case .md, .lg: return .sansXl
        }
    }
}
