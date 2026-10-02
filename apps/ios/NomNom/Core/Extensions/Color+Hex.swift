import SwiftUI
import UIKit

extension UIColor {
    /// Creates a colour from a `#rrggbb` or `#rrggbbaa` hex string (sRGB).
    /// Invalid input falls back to magenta so a typo is obvious on screen.
    convenience init(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespaces)
        if value.hasPrefix("#") { value.removeFirst() }
        var raw: UInt64 = 0
        guard Scanner(string: value).scanHexInt64(&raw), value.count == 6 || value.count == 8 else {
            self.init(red: 1, green: 0, blue: 1, alpha: 1)
            return
        }
        let hasAlpha = value.count == 8
        let r = CGFloat((raw >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
        let g = CGFloat((raw >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
        let b = CGFloat((raw >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
        let a = hasAlpha ? CGFloat(raw & 0xFF) / 255 : 1
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

extension Color {
    /// A fixed sRGB colour from a hex string.
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex)) // ds-lint:allow hex parser
    }

    /// A colour that resolves per interface style. `dark` defaults to `light`.
    init(light: String, dark: String? = nil) {
        let lightColor = UIColor(hex: light) // ds-lint:allow hex parser
        let darkColor = UIColor(hex: dark ?? light) // ds-lint:allow hex parser
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? darkColor : lightColor
        })
    }

    /// A colour that resolves per interface style from two `Color`s.
    init(light: Color, dark: Color) {
        let lightColor = UIColor(light)
        let darkColor = UIColor(dark)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? darkColor.resolvedColor(with: traits)
                : lightColor.resolvedColor(with: traits)
        })
    }
}
