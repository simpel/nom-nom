import SwiftUI

/// An individual photo source displayed in `HeroPhotoDeckView`.
enum HeroPhotoItem: Equatable, Identifiable {
    case remote(path: String, bucket: String = SupabaseConfig.photoBucket)
    case local(id: String, data: Data)
    case asset(name: String)
    case fallback(cuisine: String?)
    case party(name: String)

    var id: String {
        switch self {
        case .remote(let path, let bucket): return "\(bucket):\(path)"
        case .local(let id, _): return "local:\(id)"
        case .asset(let name): return "asset:\(name)"
        case .fallback(let cuisine): return "fallback:\(cuisine ?? "default")"
        case .party(let name): return "party:\(name)"
        }
    }
}

/// Geometry math calculations for the fanned arc layout of `HeroPhotoDeckView`.
enum HeroDeckMath {
    // MARK: - Foreground / Meal Deck Math

    static func cardSpacing(total: Int) -> CGFloat {
        guard total > 1 else { return 0 }
        return total <= 3 ? 54.0 : max(32.0, min(50.0, 220.0 / CGFloat(total)))
    }

    static func rotationAngle(for index: Int, total: Int, isFannedOut: Bool = true) -> Double {
        guard isFannedOut && total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = Double(index) - mid
        let maxAngle = min(16.0, Double(total - 1) * 4.5)
        return (rel / max(1.0, mid)) * maxAngle
    }

    static func xOffset(for index: Int, total: Int, isFannedOut: Bool = true) -> CGFloat {
        guard isFannedOut && total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = CGFloat(Double(index) - mid)
        return rel * cardSpacing(total: total)
    }

    static func yOffset(for index: Int, total: Int, isFannedOut: Bool = true) -> CGFloat {
        guard isFannedOut && total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = CGFloat(Double(index) - mid)
        let curve: CGFloat = total <= 3 ? 3.5 : min(3.0, 14.0 / CGFloat(total))
        return (rel * rel) * curve
    }

    static func scale(for index: Int, total: Int, isFannedOut: Bool = true) -> CGFloat {
        if index == 0 { return 1.0 }
        if !isFannedOut { return 0.96 }
        let mid = Double(total - 1) / 2.0
        let rel = abs(Double(index) - mid)
        return max(0.95, 1.0 - (CGFloat(rel) * 0.02))
    }

    // MARK: - Background Scattered Recipe Photos (Up to 3 photos behind the meal arc)

    static func backgroundRecipeXOffset(for index: Int, total: Int, mealTotal: Int = 3, isFannedOut: Bool = true) -> CGFloat {
        let count = min(total, 3)
        let wideSpread: CGFloat = mealTotal >= 3 ? 18.0 : 0.0
        guard isFannedOut else {
            switch index {
            case 0: return count == 1 ? 16 : -20
            case 1: return 20
            default: return 0
            }
        }

        switch (count, index) {
        case (1, 0):
            return 72.0 + (wideSpread * 0.6)
        case (2, 0):
            return -88.0 - wideSpread
        case (2, 1):
            return 86.0 + wideSpread
        case (_, 0):
            return -96.0 - wideSpread
        case (_, 1):
            return 94.0 + wideSpread
        case (_, 2):
            return -8.0
        default:
            return 0
        }
    }

    static func backgroundRecipeYOffset(for index: Int, total: Int, mealTotal: Int = 3, isFannedOut: Bool = true) -> CGFloat {
        let count = min(total, 3)
        guard isFannedOut else { return 0 }

        switch (count, index) {
        case (1, 0):
            return -12.0
        case (2, 0):
            return -10.0
        case (2, 1):
            return -8.0
        case (_, 0):
            return -10.0
        case (_, 1):
            return -8.0
        case (_, 2):
            return -22.0
        default:
            return -10.0
        }
    }

    static func backgroundRecipeRotationAngle(for index: Int, total: Int, isFannedOut: Bool = true) -> Double {
        let count = min(total, 3)
        guard isFannedOut else {
            switch index {
            case 0: return count == 1 ? -4.0 : 4.0
            case 1: return -4.0
            default: return 0
            }
        }

        switch (count, index) {
        case (1, 0):
            return -16.0
        case (2, 0):
            return 18.0
        case (2, 1):
            return -17.0
        case (_, 0):
            return 20.0
        case (_, 1):
            return -18.0
        case (_, 2):
            return 14.0
        default:
            return 0
        }
    }

    static func backgroundRecipeScale(for index: Int, total: Int, isFannedOut: Bool = true) -> CGFloat {
        switch index {
        case 2: return 0.54
        default: return 0.58
        }
    }
}
