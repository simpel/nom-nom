import SwiftUI

/// NomNom Design System tokens.
/// Sourced from curated OKLCH color palettes (Stone, Pine, and Reaction).
enum DS {
    enum Color {
        // MARK: - Semantic Roles
        static let bg = SwiftUI.Color("ds/bg")
        static let panel = SwiftUI.Color("ds/panel")
        static let sunken = SwiftUI.Color("ds/sunken")
        static let line = SwiftUI.Color("ds/line")
        static let lineStrong = SwiftUI.Color("ds/lineStrong")
        static let textPrimary = SwiftUI.Color("ds/textPrimary")
        static let textSecondary = SwiftUI.Color("ds/textSecondary")
        static let textTertiary = SwiftUI.Color("ds/textTertiary")
        static let accent = SwiftUI.Color("ds/accent")
        static let accentText = SwiftUI.Color("ds/accentText")
        static let accentSoft = SwiftUI.Color("ds/accentSoft")

        // MARK: - Stone Ramp (Hue 258°)
        enum Stone {
            static let stone0 = SwiftUI.Color("ds/stone/stone0")
            static let stone25 = SwiftUI.Color("ds/stone/stone25")
            static let stone50 = SwiftUI.Color("ds/stone/stone50")
            static let stone100 = SwiftUI.Color("ds/stone/stone100")
            static let stone200 = SwiftUI.Color("ds/stone/stone200")
            static let stone300 = SwiftUI.Color("ds/stone/stone300")
            static let stone400 = SwiftUI.Color("ds/stone/stone400")
            static let stone500 = SwiftUI.Color("ds/stone/stone500")
            static let stone600 = SwiftUI.Color("ds/stone/stone600")
            static let stone700 = SwiftUI.Color("ds/stone/stone700")
            static let stone800 = SwiftUI.Color("ds/stone/stone800")
            static let stone900 = SwiftUI.Color("ds/stone/stone900")
            static let stone950 = SwiftUI.Color("ds/stone/stone950")
            static let stone1000 = SwiftUI.Color("ds/stone/stone1000")
        }

        // MARK: - Pine Ramp (Hue 193°)
        enum Pine {
            static let pine50 = SwiftUI.Color("ds/pine/pine50")
            static let pine100 = SwiftUI.Color("ds/pine/pine100")
            static let pine200 = SwiftUI.Color("ds/pine/pine200")
            static let pine300 = SwiftUI.Color("ds/pine/pine300")
            static let pine400 = SwiftUI.Color("ds/pine/pine400")
            static let pine500 = SwiftUI.Color("ds/pine/pine500")
            static let pine600 = SwiftUI.Color("ds/pine/pine600")
            static let pine700 = SwiftUI.Color("ds/pine/pine700")
            static let pine800 = SwiftUI.Color("ds/pine/pine800")
            static let pine900 = SwiftUI.Color("ds/pine/pine900")
        }
    }

    enum Spacing {
        // MARK: - Micro / Inline Rhythm
        /// 4pt - Tightest gap (micro indicators, inline dots)
        static let xxs: CGFloat = 4
        /// 8pt - Standard compact gap (icon to label, metadata row items)
        static let xs: CGFloat = 8
        /// 12pt - Form control spacing, sub-card groupings
        static let sm: CGFloat = 12
        /// 16pt - Card internal padding & close element groups
        static let md: CGFloat = 16

        // MARK: - Macro / Section Rhythm
        /// 24pt - Related section subsections or compact sheet groupings
        static let sectionCompact: CGFloat = 24
        /// 32pt - Primary standard vertical gap between distinct cards & sections
        static let section: CGFloat = 32
        /// 40pt - Large editorial separation between major structural areas
        static let sectionLarge: CGFloat = 40

        // MARK: - Hero Rhythm & Breathing Room
        /// 28pt - Gap between hero card deck and hero page title/subtitle
        static let heroInner: CGFloat = 28
        /// 40pt - Clearance from hero header block to first content card below
        static let heroToContent: CGFloat = 40
        /// 14pt - Internal vertical breathing room around fanned arc card decks
        static let heroDeckPadding: CGFloat = 14

        // MARK: - Screen Bounds & View Insets
        /// 16pt - Standard horizontal gutter
        static let screenHorizontal: CGFloat = 16
        /// 20pt - ScrollView top clearance below navigation title
        static let screenTop: CGFloat = 20
        /// 44pt - ScrollView bottom clearance above tab bar or sheet bottom
        static let screenBottom: CGFloat = 44
    }
}
