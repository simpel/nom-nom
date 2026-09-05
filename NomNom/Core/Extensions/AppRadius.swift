import SwiftUI

/// Central design tokens for corner radius across the Nom Nom app.
///
/// Modifying `AppRadius.standard` updates cards, buttons, input fields,
/// pickers, and media elements across the entire app.
public enum AppRadius {
    /// Central/default radius applied across the app (2px).
    public static var standard: CGFloat = 2

    /// Radius specifically for cards and container backgrounds.
    public static var card: CGFloat { standard }

    /// Radius specifically for buttons and interactive controls.
    public static var button: CGFloat { standard }

    /// Radius specifically for text fields, search bars, and input backgrounds.
    public static var input: CGFloat { standard }

    /// Radius specifically for pickers and selector segments.
    public static var picker: CGFloat { standard }

    /// Radius specifically for photos and media cards.
    public static var photo: CGFloat = 16

    /// Sharp corner (0px).
    public static let none: CGFloat = 0
}

extension CGFloat {
    /// App-wide central corner radius.
    static var appCornerRadius: CGFloat { AppRadius.standard }
}

extension RoundedRectangle {
    /// Standard continuous RoundedRectangle configured with the app's central radius.
    static func appDefault(radius: CGFloat = AppRadius.standard) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}
