import SwiftUI
import UIKit

/// Single source of truth for app-wide typography styles, font names, and metrics.
enum AppTypography {
    // MARK: - Font Names
    static let pageTitleFontName = "Newsreader16pt-Regular"
    static let navBarTitleFontName = "Inter-Light" // 300 weight

    // MARK: - Font Sizes
    static let pageTitleFontSize: CGFloat = 32
    static let navBarTitleFontSize: CGFloat = 17

    // MARK: - UIKit Fonts (Navigation Bars)
    static var largePageTitleUIFont: UIFont? {
        UIFont(name: pageTitleFontName, size: pageTitleFontSize)
    }

    static var navBarTitleUIFont: UIFont? {
        UIFont(name: navBarTitleFontName, size: navBarTitleFontSize)
    }

    // MARK: - SwiftUI Fonts
    static var pageTitleFont: Font {
        Font.custom(pageTitleFontName, size: pageTitleFontSize, relativeTo: .largeTitle)
    }
}
