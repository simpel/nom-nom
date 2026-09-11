import SwiftUI

/// Central design tokens for corner radius across the Nom Nom app.
///
/// Modifying `AppRadius.standard` updates cards, buttons, input fields,
/// pickers, and media elements across the entire app.
public enum AppRadius {
    /// Central/default radius applied across the app (12px).
    public static var standard: CGFloat = 12

    /// Small radius for compact score boxes, badges, and segmented elements (8px).
    public static var small: CGFloat = 8

    /// Radius specifically for cards and container backgrounds (14px).
    public static var card: CGFloat = 14

    /// Radius specifically for buttons and interactive controls (50px / capsule).
    public static var button: CGFloat = 50

    /// Radius specifically for text fields, search bars, and input backgrounds (10px).
    public static var input: CGFloat = 10

    /// Radius specifically for pickers and selector segments (10px).
    public static var picker: CGFloat = 10

    /// Radius specifically for photos and media cards (16px).
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
