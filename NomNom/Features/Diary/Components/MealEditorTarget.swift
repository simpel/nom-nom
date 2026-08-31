import Foundation

/// What the meal editor sheet should open with.
enum MealEditorTarget: Identifiable {
    case new
    case existing(UUID)

    var id: String {
        switch self {
        case .new: return "new"
        case .existing(let id): return id.uuidString
        }
    }

    var mealID: UUID? {
        switch self {
        case .new: return nil
        case .existing(let id): return id
        }
    }
}
