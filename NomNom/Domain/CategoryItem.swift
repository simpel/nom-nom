import Foundation

/// Unified category / kitchen entity representing either a built-in preset or a custom category.
struct CategoryItem: Identifiable, Hashable {
    var id: String { name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
    let name: String
    var photoPath: String?

    var displayName: String {
        if let preset = Cuisine.matching(from: name) {
            return preset.displayName
        }
        return name.capitalized
    }

    var preset: Cuisine? {
        Cuisine.matching(from: name)
    }

    var assetImageName: String? {
        preset?.assetImageName
    }

    init(name: String, photoPath: String? = nil) {
        self.name = name
        self.photoPath = photoPath
    }

    init(cuisine: Cuisine, photoPath: String? = nil) {
        self.name = cuisine.rawValue
        self.photoPath = photoPath
    }

    init(record: CategoryRecord) {
        self.name = record.slug
        self.photoPath = record.photoPath
    }
}
