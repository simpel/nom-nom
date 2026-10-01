import SwiftUI
import UIKit

extension DS {
    /// The design system's type scale: Newsreader serif xs–xl and the system
    /// sans xs–xl. A step is one size plus one leading; serif md and up use
    /// Newsreader's 72pt display cut. Only regular and semibold exist.
    enum TextStyle: CaseIterable {
        case serifXs, serifSm, serifMd, serifLg, serifXl
        case sansXs, sansSm, sansMd, sansLg, sansXl

        enum Weight { case regular, semibold }

        var size: CGFloat {
            switch self {
            case .serifXs: return 20
            case .serifSm: return 24
            case .serifMd: return 30
            case .serifLg: return 36
            case .serifXl: return 48
            case .sansXs: return 12
            case .sansSm: return 14
            case .sansMd: return 16
            case .sansLg: return 18
            case .sansXl: return 20
            }
        }

        /// Line height as a multiple of size (`leading-*`).
        var leading: CGFloat {
            switch self {
            case .serifXs, .serifSm: return 1.375
            case .serifMd, .serifLg: return 1.25
            case .serifXl: return 1.0
            default: return 1.5
            }
        }

        var isSerif: Bool {
            switch self {
            case .serifXs, .serifSm, .serifMd, .serifLg, .serifXl: return true
            default: return false
            }
        }

        /// Serif md and up use the 72pt optical cut.
        var usesDisplayCut: Bool {
            switch self {
            case .serifMd, .serifLg, .serifXl: return true
            default: return false
            }
        }

        var defaultWeight: Weight { self == .sansLg ? .semibold : .regular }

        /// `tracking-tight` (−0.025em) on large serif.
        var tracking: CGFloat {
            switch self {
            case .serifLg, .serifXl: return -0.025 * size
            default: return 0
            }
        }

        /// The Dynamic Type style this step scales with.
        var relativeTo: Font.TextStyle {
            switch self {
            case .serifXs, .sansXl: return .title3
            case .serifSm: return .title2
            case .serifMd: return .title
            case .serifLg, .serifXl: return .largeTitle
            case .sansXs: return .caption
            case .sansSm: return .subheadline
            case .sansMd: return .callout
            case .sansLg: return .body
            }
        }

        /// The style's font at its default weight.
        var font: Font { font(weight: nil, italic: false) }

        func font(weight: Weight? = nil, italic: Bool = false, dynamicTypeSize: DynamicTypeSize? = nil) -> Font {
            if isSerif {
                return Font.custom(fontName(italic: italic), size: size, relativeTo: relativeTo)
            }
            let resolved = (weight ?? defaultWeight) == .semibold ? Font.Weight.semibold : .regular
            let base = Font.system(size: scaledSize(dynamicTypeSize), weight: resolved)
            return italic ? base.italic() : base
        }

        /// PostScript name for the serif face. There is no 72pt italic; italic
        /// always uses the 16pt text cut.
        func fontName(italic: Bool = false) -> String {
            if italic { return "Newsreader16pt-Italic" }
            return usesDisplayCut ? "Newsreader72pt-Regular" : "Newsreader16pt-Regular"
        }

        func scaledSize(_ dynamicTypeSize: DynamicTypeSize? = nil) -> CGFloat {
            let metrics = UIFontMetrics(forTextStyle: relativeTo.uiTextStyle)
            guard let dynamicTypeSize else { return metrics.scaledValue(for: size) }
            let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
            return metrics.scaledValue(for: size, compatibleWith: traits)
        }

        /// Extra spacing between lines so the rendered line height matches `leading`.
        func lineSpacing(_ dynamicTypeSize: DynamicTypeSize? = nil) -> CGFloat {
            let pointSize = scaledSize(dynamicTypeSize)
            let natural = isSerif
                ? (UIFont(name: fontName(), size: pointSize)?.lineHeight ?? pointSize * 1.2)
                : UIFont.systemFont(ofSize: pointSize).lineHeight
            return max(0, pointSize * leading - natural)
        }
    }

    /// Text ink, the spec's `tone`.
    enum Tone {
        case primary, secondary, tertiary, accent

        var color: SwiftUI.Color {
            switch self {
            case .primary: return DS.Color.textPrimary
            case .secondary: return DS.Color.textSecondary
            case .tertiary: return DS.Color.textTertiary
            case .accent: return DS.Color.primaryText
            }
        }
    }
}

private struct DSTextStyleModifier: ViewModifier {
    let style: DS.TextStyle
    let tone: DS.Tone?
    let weight: DS.TextStyle.Weight?
    let italic: Bool
    let numeric: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ViewBuilder
    func body(content: Content) -> some View {
        let font = style.font(weight: weight, italic: italic, dynamicTypeSize: dynamicTypeSize)
        let styled = content
            .font(numeric ? font.monospacedDigit() : font)
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing(dynamicTypeSize))
        // `tone: nil` inherits the surrounding foreground style.
        if let tone {
            styled.foregroundStyle(tone.color)
        } else {
            styled
        }
    }
}

extension View {
    /// Sets copy in a design-system text style: font, line height and tone.
    /// Pass `numeric: true` for tabular figures (scores, anything in a column).
    func textStyle(
        _ style: DS.TextStyle,
        tone: DS.Tone? = .primary,
        weight: DS.TextStyle.Weight? = nil,
        italic: Bool = false,
        numeric: Bool = false
    ) -> some View {
        modifier(DSTextStyleModifier(style: style, tone: tone, weight: weight, italic: italic, numeric: numeric))
    }
}

private extension Font.TextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        default: return .body
        }
    }
}
