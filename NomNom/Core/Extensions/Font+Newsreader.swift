import SwiftUI

extension Font {
    /// Newsreader font name resolution based on weight and italic style.
    private static func newsreaderFontName(for weight: Font.Weight, italic: Bool = false) -> String {
        switch (weight, italic) {
        case (.ultraLight, _), (.thin, _):
            return "Newsreader16pt-ExtraLight"
        case (.light, _):
            return "Newsreader16pt-Light"
        case (.bold, true), (.heavy, true), (.black, true):
            return "Newsreader16pt-BoldItalic"
        case (.bold, false), (.heavy, false), (.black, false):
            return "Newsreader16pt-Bold"
        case (.semibold, true):
            return "Newsreader16pt-SemiBoldItalic"
        case (.semibold, false):
            return "Newsreader16pt-SemiBold"
        case (.medium, true):
            return "Newsreader16pt-MediumItalic"
        case (.medium, false):
            return "Newsreader16pt-Medium"
        case (_, true):
            return "Newsreader16pt-Italic"
        default:
            return "Newsreader16pt-Regular"
        }
    }

    /// Creates a Newsreader serif font with Dynamic Type scaling.
    static func newsreader(
        size: CGFloat = 32,
        weight: Font.Weight = .regular,
        italic: Bool = false,
        relativeTo textStyle: Font.TextStyle = .largeTitle
    ) -> Font {
        let name = newsreaderFontName(for: weight, italic: italic)
        return Font.custom(name, size: size, relativeTo: textStyle)
    }

    /// Creates a Newsreader serif font matching a standard Apple Dynamic Type text style.
    static func newsreader(
        _ style: Font.TextStyle,
        weight: Font.Weight? = nil,
        italic: Bool = false
    ) -> Font {
        let (defaultSize, defaultWeight) = defaultMetrics(for: style)
        let resolvedWeight = weight ?? defaultWeight
        let name = newsreaderFontName(for: resolvedWeight, italic: italic)
        return Font.custom(name, size: defaultSize, relativeTo: style)
    }

    private static func defaultMetrics(for style: Font.TextStyle) -> (size: CGFloat, weight: Font.Weight) {
        switch style {
        case .largeTitle, .title:
            return (32, .regular)
        case .title2:
            return (24, .regular)
        case .title3:
            return (20, .regular)
        case .headline:
            return (17, .regular)
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

    // MARK: - Centralized Editorial Heading Tokens

    /// Standardized main screen and hero heading (32pt Newsreader Regular from AppTypography).
    /// Used consistently across screen titles and hero headers ("Add gassy had Asdf asdf").
    static var mainHeading: Font {
        AppTypography.pageTitleFont
    }

    /// Primary hero title for meal narrative (aligned to AppTypography.pageTitleFont).
    static var mealHeroTitle: Font {
        mainHeading
    }

    /// Italic quote or chef reflection in Newsreader.
    static var editorialQuote: Font {
        newsreader(size: 16, weight: .regular, italic: true, relativeTo: .callout)
    }
}
