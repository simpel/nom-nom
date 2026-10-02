import SwiftUI
import UIKit

extension DS {
    /// The design system's type scale: Newsreader serif xs–xl and the system
    /// sans xs–xl. Size, line height, family and the Dynamic Type style each step
    /// scales with all come from `DSTokens.TypeStyles` (tokens.json `type` plus the
    /// README "Dynamic Type" table).
    ///
    /// README "Typography": "Every step in the scale is regular (400), at every
    /// size. Weight is a separate axis a component opts into" — so no case carries
    /// a weight of its own; pass `weight: .semibold` at the call site.
    enum TextStyle: CaseIterable {
        case serifXs, serifSm, serifMd, serifLg, serifXl
        case sansXs, sansSm, sansMd, sansLg, sansXl

        /// The two weights that exist (`font-weight-normal`, `font-weight-semibold`).
        /// Text README `weight`: `normal` · `semibold`.
        enum Weight {
            case normal, semibold

            @available(*, deprecated, renamed: "normal")
            static var regular: Weight { .normal }

            var token: Int {
                switch self {
                case .normal: return DSTokens.FontWeight.normal
                case .semibold: return DSTokens.FontWeight.semibold
                }
            }

            /// The SwiftUI weight for the CSS numeric weight.
            var fontWeight: Font.Weight {
                token >= DSTokens.FontWeight.semibold ? .semibold : .regular
            }

            /// The UIKit weight for the CSS numeric weight.
            var uiFontWeight: UIFont.Weight {
                token >= DSTokens.FontWeight.semibold ? .semibold : .regular
            }
        }

        var token: DSTokens.TypeStyle {
            switch self {
            case .serifXs: return DSTokens.TypeStyles.serifXs
            case .serifSm: return DSTokens.TypeStyles.serifSm
            case .serifMd: return DSTokens.TypeStyles.serifMd
            case .serifLg: return DSTokens.TypeStyles.serifLg
            case .serifXl: return DSTokens.TypeStyles.serifXl
            case .sansXs: return DSTokens.TypeStyles.sansXs
            case .sansSm: return DSTokens.TypeStyles.sansSm
            case .sansMd: return DSTokens.TypeStyles.sansMd
            case .sansLg: return DSTokens.TypeStyles.sansLg
            case .sansXl: return DSTokens.TypeStyles.sansXl
            }
        }

        /// Font size at the default Dynamic Type setting.
        var size: CGFloat { token.size }

        /// Line height as a multiple of size (`leading-*`).
        var leading: CGFloat { token.lineHeight }

        var family: DSTokens.FontFamily { token.family }

        var isSerif: Bool { family.postScriptName != nil }

        /// The Dynamic Type style this step scales with.
        var relativeTo: Font.TextStyle { token.relativeTo }

        /// `tracking-tight` in points at this size. Opt-in; no step applies it itself.
        var trackingTight: CGFloat { DSTokens.Tracking.tight * size }

        /// `tracking-widest` in points: uppercase overlines and section headers.
        var trackingWidest: CGFloat { DSTokens.Tracking.widest * size }

        /// The style's font at the regular weight.
        var font: Font { font(weight: nil, italic: false) }

        func font(weight: Weight? = nil, italic: Bool = false, dynamicTypeSize: DynamicTypeSize? = nil) -> Font {
            if let name = fontName(italic: italic) {
                return Font.custom(name, size: size, relativeTo: relativeTo)
            }
            let base = Font.system(size: scaledSize(dynamicTypeSize), weight: (weight ?? .normal).fontWeight)
            return italic ? base.italic() : base
        }

        /// The style as a UIKit font that follows Dynamic Type (UIKit appearance
        /// proxies such as the navigation bar).
        func uiFont(weight: Weight? = nil) -> UIFont {
            let metrics = UIFontMetrics(forTextStyle: relativeTo.uiTextStyle)
            if let name = fontName(), let custom = UIFont(name: name, size: size) {
                return metrics.scaledFont(for: custom)
            }
            return metrics.scaledFont(for: UIFont.systemFont(ofSize: size, weight: (weight ?? .normal).uiFontWeight))
        }

        /// PostScript name of the bundled serif cut, `nil` for the system sans.
        /// Italic exists only in the `serif` family, so every serif italic uses it.
        func fontName(italic: Bool = false) -> String? {
            guard isSerif else { return nil }
            if italic { return family.italicPostScriptName ?? DSTokens.FontFamily.serif.italicPostScriptName }
            return family.postScriptName
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
            let system = UIFont.systemFont(ofSize: pointSize)
            let natural = fontName().flatMap { UIFont(name: $0, size: pointSize) }?.lineHeight ?? system.lineHeight
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
    let lines: Int?
    let align: TextAlignment?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ViewBuilder
    func body(content: Content) -> some View {
        let font = style.font(weight: weight, italic: italic, dynamicTypeSize: dynamicTypeSize)
        let styled = content
            .font(numeric ? font.monospacedDigit() : font)
            .lineSpacing(style.lineSpacing(dynamicTypeSize))
            .modifier(DSTextLayoutModifier(lines: lines, align: align))
        // `tone: nil` inherits the surrounding foreground style.
        if let tone {
            styled.foregroundStyle(tone.color)
        } else {
            styled
        }
    }
}

/// Text README `lines` (clamp) and `align` (`center`); `nil` leaves the environment's.
private struct DSTextLayoutModifier: ViewModifier {
    let lines: Int?
    let align: TextAlignment?

    @ViewBuilder
    func body(content: Content) -> some View {
        switch (lines, align) {
        case let (lines?, align?): content.lineLimit(lines).multilineTextAlignment(align)
        case let (lines?, nil): content.lineLimit(lines)
        case let (nil, align?): content.multilineTextAlignment(align)
        case (nil, nil): content
        }
    }
}

extension View {
    /// The spec's `Text`: sets copy in a design-system text style (font, line height,
    /// Dynamic Type) and a tone. Every step is regular; opt into `weight: .semibold`
    /// and `italic` per call site. `numeric: true` sets tabular figures (scores,
    /// anything in a column); `lines` clamps; `align: .center` centres.
    /// `tone: nil` inherits the surrounding foreground style.
    func textStyle(
        _ style: DS.TextStyle,
        tone: DS.Tone? = .primary,
        weight: DS.TextStyle.Weight? = nil,
        italic: Bool = false,
        numeric: Bool = false,
        lines: Int? = nil,
        align: TextAlignment? = nil
    ) -> some View {
        modifier(DSTextStyleModifier(
            style: style, tone: tone, weight: weight, italic: italic,
            numeric: numeric, lines: lines, align: align
        ))
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
