import SwiftUI

// Raw Stone and Pine ramps from `tokens.json`. Views consume the semantic
// roles in `DS.Color`, never these ramps directly; they exist so the roles
// (and the odd one-off like a chart gradient) resolve from one table.

extension DS.Color {
    /// Stone neutrals (hue 258°). Fixed values; they do not adapt to dark mode.
    enum Stone {
        static let stone0 = Color(hex: Hex.stone0)
        static let stone25 = Color(hex: "#fafbfc")
        static let stone50 = Color(hex: "#f5f7f9")
        static let stone100 = Color(hex: Hex.stone100)
        static let stone200 = Color(hex: "#e3e5e9")
        static let stone300 = Color(hex: Hex.stone300)
        static let stone400 = Color(hex: Hex.stone400)
        static let stone500 = Color(hex: "#8a8f97")
        static let stone600 = Color(hex: "#6b7178")
        static let stone700 = Color(hex: Hex.stone700)
        static let stone800 = Color(hex: Hex.stone800)
        static let stone900 = Color(hex: Hex.stone900)
        static let stone950 = Color(hex: "#0f1217")
        static let stone1000 = Color(hex: Hex.stone1000)
    }

    /// Pine accent ramp (hue 193°). Fixed values; they do not adapt to dark mode.
    enum Pine {
        static let pine50 = Color(hex: "#ecf9f8")
        static let pine100 = Color(hex: "#d7f2f0")
        static let pine200 = Color(hex: "#b5e4e2")
        static let pine300 = Color(hex: Hex.pine300)
        static let pine400 = Color(hex: Hex.pine400)
        static let pine500 = Color(hex: "#07817f")
        static let pine600 = Color(hex: "#0a6867")
        static let pine700 = Color(hex: "#055150")
        static let pine800 = Color(hex: "#013b3a")
        static let pine900 = Color(hex: Hex.pine900)
    }

    /// Hex strings for the ramp steps that semantic roles alias in dark mode.
    enum Hex {
        static let stone0 = "#ffffff"
        static let stone100 = "#eff1f4"
        static let stone300 = "#d0d4d9"
        static let stone400 = "#adb1b8"
        static let stone700 = "#4d525a"
        static let stone800 = "#31363c"
        static let stone900 = "#1c2026"
        static let stone1000 = "#06080c"
        static let pine300 = "#87ccca"
        static let pine400 = "#4aa3a0"
        static let pine900 = "#002a29"
    }
}
