import SwiftUI

/// Predefined sizes for ScoreBadge.
enum ScoreBadgeSize {
    case sm
    case md
    case lg

    var font: Font {
        switch self {
        case .sm: return .caption2.weight(.medium)
        case .md: return .caption.weight(.medium)
        case .lg: return .subheadline.weight(.medium)
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .sm: return 7
        case .md: return 9
        case .lg: return 12
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .sm: return 2.5
        case .md: return 3.5
        case .lg: return 5
        }
    }

    var itemSpacing: CGFloat {
        switch self {
        case .sm: return 5
        case .md: return 6
        case .lg: return 8
        }
    }

    var dividerHeight: CGFloat {
        switch self {
        case .sm: return 9
        case .md: return 11
        case .lg: return 13
        }
    }
}

/// Content format options for ScoreBadge.
enum ScoreBadgeFormat {
    /// Displays score scalar integer only: "75"
    case scoreOnly
    /// Displays miniature divided score and verdict: "75 │ Great"
    case both
    /// Displays qualitative verdict only: "Great"
    case verdictOnly
}

/// Visual presentation styles for ScoreBadge background.
enum ScoreBadgeStyle {
    /// Tinted background matching the reaction color, no border.
    case tinted
    /// Subtle neutral background, secondary text color, no border.
    case subtle
    /// Transparent background with reaction foreground, no border.
    case ghost
}
