import SwiftUI

/// An individual photo source displayed in `HeroPhotoDeckView`.
enum HeroPhotoItem: Equatable, Identifiable {
    case remote(path: String, bucket: String = SupabaseConfig.photoBucket)
    case local(id: String, data: Data)
    case asset(name: String)
    case fallback(cuisine: String?)

    var id: String {
        switch self {
        case .remote(let path, let bucket): return "\(bucket):\(path)"
        case .local(let id, _): return "local:\(id)"
        case .asset(let name): return "asset:\(name)"
        case .fallback(let cuisine): return "fallback:\(cuisine ?? "default")"
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

    // MARK: - Dual Deck Left Wing (Meal Photos Tilted to the Left)

    static func dualMealXOffset(for index: Int, total: Int, isFannedOut: Bool = true) -> CGFloat {
        guard isFannedOut else { return -32.0 }
        let baseCenter: CGFloat = total <= 2 ? -36.0 : -46.0
        guard total > 1 else { return baseCenter }
        let mid = Double(total - 1) / 2.0
        let rel = CGFloat(Double(index) - mid)
        let spacing: CGFloat = total <= 2 ? 28.0 : (total <= 3 ? 24.0 : 20.0)
        return baseCenter + (rel * spacing)
    }

    static func dualMealYOffset(for index: Int, total: Int, isFannedOut: Bool = true) -> CGFloat {
        guard isFannedOut && total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = CGFloat(Double(index) - mid)
        return (rel * rel) * 1.5
    }

    static func dualMealRotationAngle(for index: Int, total: Int, isFannedOut: Bool = true) -> Double {
        guard isFannedOut else { return -14.0 }
        let baseTilt: Double = -22.0
        guard total > 1 else { return baseTilt }
        let mid = Double(total - 1) / 2.0
        let rel = Double(index) - mid
        let spread: Double = total <= 2 ? 6.5 : (total <= 3 ? 5.5 : 4.8)
        return baseTilt + (rel * spread)
    }

    static func dualMealScale(for index: Int, total: Int, isFannedOut: Bool = true) -> CGFloat {
        let baseScale: CGFloat = 0.98
        guard isFannedOut && total > 1 else { return baseScale }
        let mid = Double(total - 1) / 2.0
        let rel = abs(Double(index) - mid)
        return max(0.94, baseScale - (CGFloat(rel) * 0.02))
    }

    // MARK: - Dual Deck Right Wing (Recipe Photos Tilted to the Right - Way Smaller)

    static func dualRecipeXOffset(for index: Int, total: Int, isFannedOut: Bool = true) -> CGFloat {
        guard isFannedOut else { return 36.0 }
        let baseCenter: CGFloat = total <= 2 ? 44.0 : 54.0
        guard total > 1 else { return baseCenter }
        let mid = Double(total - 1) / 2.0
        let rel = CGFloat(Double(index) - mid)
        let spacing: CGFloat = total <= 2 ? 22.0 : (total <= 3 ? 18.0 : 16.0)
        return baseCenter + (rel * spacing)
    }

    static func dualRecipeYOffset(for index: Int, total: Int, isFannedOut: Bool = true) -> CGFloat {
        guard isFannedOut && total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = CGFloat(Double(index) - mid)
        return (rel * rel) * 1.5
    }

    static func dualRecipeRotationAngle(for index: Int, total: Int, isFannedOut: Bool = true) -> Double {
        guard isFannedOut else { return 14.0 }
        let baseTilt: Double = 22.0
        guard total > 1 else { return baseTilt }
        let mid = Double(total - 1) / 2.0
        let rel = Double(index) - mid
        let spread: Double = total <= 2 ? 6.5 : (total <= 3 ? 5.5 : 4.8)
        return baseTilt + (rel * spread)
    }

    static func dualRecipeScale(for index: Int, total: Int, isFannedOut: Bool = true) -> CGFloat {
        let baseScale: CGFloat = 0.65 // Way smaller for recipe photos
        guard isFannedOut && total > 1 else { return baseScale }
        let mid = Double(total - 1) / 2.0
        let rel = abs(Double(index) - mid)
        return max(0.60, baseScale - (CGFloat(rel) * 0.02))
    }
}
