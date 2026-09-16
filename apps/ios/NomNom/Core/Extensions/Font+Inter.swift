import SwiftUI

extension Font {
    /// Inter font family name mapping based on weight.
    private static func interFontName(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light:
            return "Inter-Light"
        case .medium:
            return "Inter-Medium"
        case .semibold:
            return "Inter-SemiBold"
        case .bold, .heavy, .black:
            return "Inter-Bold"
        default:
            return "Inter-Regular"
        }
    }

    /// Creates an Inter font for a specific point size with Dynamic Type scaling.
    static func inter(
        size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        let name = interFontName(for: weight)
        return Font.custom(name, size: size, relativeTo: textStyle)
    }

    /// Creates an Inter font matching a standard Apple Dynamic Type text style.
    static func inter(_ style: Font.TextStyle, weight: Font.Weight? = nil) -> Font {
        let (defaultSize, defaultWeight) = defaultMetrics(for: style)
        let resolvedWeight = weight ?? defaultWeight
        let name = interFontName(for: resolvedWeight)
        return Font.custom(name, size: defaultSize, relativeTo: style)
    }

    private static func defaultMetrics(for style: Font.TextStyle) -> (size: CGFloat, weight: Font.Weight) {
        switch style {
        case .largeTitle:
            return (34, .regular)
        case .title:
            return (28, .regular)
        case .title2:
            return (22, .regular)
        case .title3:
            return (20, .regular)
        case .headline:
            return (17, .semibold)
        case .body:
            return (17, .regular)
        case .callout:
            return (16, .regular)
        case .subheadline:
            return (15, .regular)
        case .footnote:
            return (13, .regular)
        case .caption:
            return (12, .regular)
        case .caption2:
            return (11, .regular)
        @unknown default:
            return (17, .regular)
        }
    }

    // MARK: - Semantic Shorthands

    static var interLargeTitle: Font { inter(.largeTitle) }
    static var interTitle: Font { inter(.title) }
    static var interTitle2: Font { inter(.title2) }
    static var interTitle3: Font { inter(.title3) }
    static var interHeadline: Font { inter(.headline) }
    static var interSubheadline: Font { inter(.subheadline) }
    static var interBody: Font { inter(.body) }
    static var interCallout: Font { inter(.callout) }
    static var interFootnote: Font { inter(.footnote) }
    static var interCaption: Font { inter(.caption) }
    static var interCaption2: Font { inter(.caption2) }
}
