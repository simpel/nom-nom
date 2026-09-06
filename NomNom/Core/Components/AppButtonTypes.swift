import SwiftUI

/// Standard button variants representing hierarchy and intent.
enum AppButtonVariant {
    case primary
    case secondary
    case neutral
    case destructive
}

/// Visual styles for button backgrounds and borders.
enum AppButtonStyle {
    case normal
    case outlined
    case ghost
}

/// Icon representation supporting system SF Symbols, named assets, or custom SwiftUI Images.
enum AppButtonIcon: ExpressibleByStringLiteral {
    case system(String)
    case asset(String)
    case image(Image)

    init(stringLiteral value: String) {
        self = .system(value)
    }
}

/// Icon position relative to the button title label.
enum AppButtonIconPosition {
    case leading
    case trailing
}

/// Predefined sizes matching app typography and input field heights.
enum AppButtonSize {
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
        case .sm: return 12
        case .md: return 16
        case .xl: return 20
        }
    }

    var font: Font {
        switch self {
        case .sm: return .subheadline
        case .md: return .callout
        case .xl: return .headline
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

/// Smooth spring compression animation on press.
struct AppPressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
