import Foundation

extension PhotoCardSource {
    /// A category's photo: its generated cover in the category bucket, falling back to
    /// the cuisine's category photograph, then the no-photo tile.
    static func category(_ category: CategoryItem) -> PhotoCardSource {
        .remote(path: category.photoPath, bucket: SupabaseConfig.categoryBucket, cuisine: category.name)
    }
}

extension CategoryItem {
    /// "1 recipe" / "12 recipes", the LabeledPhotoCard meta line.
    static func recipeCountText(_ count: Int) -> String {
        count == 1 ? "1 recipe" : "\(count) recipes"
    }
}
