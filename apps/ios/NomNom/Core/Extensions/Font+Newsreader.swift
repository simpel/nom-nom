import SwiftUI

/// Newsreader fonts by design-system step. Sizes come only from `DS.TextStyle`
/// (tokens.json `type`); there is no free size here. Newsreader is bundled in three
/// cuts (16pt Regular, 16pt Italic, 72pt display Regular) and the system has no
/// serif weights, so the face is always Regular.
/// Prefer `.textStyle(.serif…)` in new code; it also sets line height and tone.
extension Font {
    /// A serif step's font, with Dynamic Type scaling.
    static func newsreader(_ style: DS.TextStyle, italic: Bool = false) -> Font {
        style.font(italic: italic)
    }

    /// Pre-v3 API keyed by an iOS text style. Maps through the README "Dynamic Type"
    /// table (the serif step declared relative to that text style); anything smaller
    /// than `.title3` becomes `serif-xs` — README: "Nothing is set in serif below
    /// text-xl." `weight` is ignored.
    @available(*, deprecated, message: "Use Font.newsreader(_: DS.TextStyle) or .textStyle(.serif…)")
    static func newsreader(
        _ style: Font.TextStyle,
        weight: Font.Weight? = nil,
        italic: Bool = false
    ) -> Font {
        newsreader(DS.TextStyle.serif(relativeTo: style), italic: italic)
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

extension DS.TextStyle {
    /// The serif step whose Dynamic Type style is `textStyle` (README "Dynamic Type":
    /// serif-xs `.title3`, serif-sm `.title2`, serif-md `.title`, serif-lg
    /// `.largeTitle`). `.largeTitle` is shared by serif-lg and serif-xl; it maps to
    /// serif-lg, the title step.
    static func serif(relativeTo textStyle: Font.TextStyle) -> DS.TextStyle {
        let serifSteps: [DS.TextStyle] = [.serifLg, .serifMd, .serifSm, .serifXs]
        return serifSteps.first { $0.relativeTo == textStyle } ?? .serifXs
    }
}
