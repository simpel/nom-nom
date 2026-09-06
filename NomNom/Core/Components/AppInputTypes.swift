import SwiftUI

/// Standard input sizes aligned with AppButton heights and typography tokens.
enum AppInputSize {
    case sm
    case md
    case xl

    var height: CGFloat {
        switch self {
        case .sm: return 34
        case .md: return 42
        case .xl: return 50
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .sm: return 10
        case .md: return 14
        case .xl: return 16
        }
    }

    var font: Font {
        switch self {
        case .sm: return .subheadline
        case .md: return .body
        case .xl: return .body
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .sm: return 14
        case .md: return 16
        case .xl: return 18
        }
    }
}

/// Visual styles for input container backgrounds and borders.
enum AppInputStyle {
    /// Sunken surface background with subtle resting border and accented focus ring.
    case filled
    /// Transparent surface with structural border.
    case outlined
    /// Transparent surface without borders, ideal for seamless inline table rows.
    case plain
}

/// Container geometry for input fields.
enum AppInputShape: Equatable {
    case rounded(CGFloat = AppRadius.input)
    case capsule
}

/// Leading or trailing icon representation supporting system symbols, assets, or images.
enum AppInputIcon: ExpressibleByStringLiteral {
    case system(String)
    case asset(String)
    case image(Image)

    init(stringLiteral value: String) {
        self = .system(value)
    }
}
