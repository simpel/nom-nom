import SwiftUI

/// Newsreader is bundled in three cuts only: 16pt Regular, 16pt Italic and
/// 72pt (display) Regular. The design system has no serif weights, so any
/// `weight` passed here is ignored and the face is always Regular.
/// Prefer `.textStyle(.serif…)` / `DS.TextStyle.serif….font` in new code.
extension Font {
    private static func newsreaderFontName(size: CGFloat, italic: Bool) -> String {
        if italic { return "Newsreader16pt-Italic" }
        return size >= DS.TextStyle.serifMd.size ? "Newsreader72pt-Regular" : "Newsreader16pt-Regular"
    }

    /// Creates a Newsreader serif font with Dynamic Type scaling.
    /// `weight` is accepted for source compatibility and mapped to Regular.
    static func newsreader(
        size: CGFloat = 32,
        weight: Font.Weight = .regular,
        italic: Bool = false,
        relativeTo textStyle: Font.TextStyle = .largeTitle
    ) -> Font {
        Font.custom(newsreaderFontName(size: size, italic: italic), size: size, relativeTo: textStyle)
    }

    /// Creates a Newsreader serif font matching a standard Dynamic Type text style.
    /// `weight` is accepted for source compatibility and mapped to Regular.
    static func newsreader(
        _ style: Font.TextStyle,
        weight: Font.Weight? = nil,
        italic: Bool = false
    ) -> Font {
        let size = defaultSize(for: style)
        return Font.custom(newsreaderFontName(size: size, italic: italic), size: size, relativeTo: style)
    }

    private static func defaultSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle, .title: return 32
        case .title2: return 24
        case .title3: return 20
        case .headline, .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        @unknown default: return 17
        }
    }

    // MARK: - Editorial shorthands (mapped onto DS.TextStyle)

    /// Screen and hero heading.
    static var mainHeading: Font { DS.TextStyle.serifLg.font }

    /// Hero title for the meal narrative.
    static var mealHeroTitle: Font { mainHeading }

    /// Editorial section heading.
    static var sectionHeading: Font { DS.TextStyle.serifXs.font }

    /// Editorial sub-heading. Nothing is set in serif below `serif-xs`.
    static var subHeading: Font { DS.TextStyle.serifXs.font }

    /// Editorial summary text.
    static var editorialSummary: Font { DS.TextStyle.serifXs.font }

    /// Italic quote or cook's note.
    static var editorialQuote: Font { DS.TextStyle.serifXs.font(italic: true) }
}
