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
}
