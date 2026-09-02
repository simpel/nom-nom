import CoreText
import Foundation

/// Ensures all bundled custom fonts (Inter and Newsreader) are loaded into CoreText at launch.
enum FontRegistry {
    private static var isRegistered = false

    static func registerFonts() {
        guard !isRegistered else { return }
        isRegistered = true

        let fontFiles = [
            "Inter-Light.ttf",
            "Inter-Regular.ttf",
            "Inter-Medium.ttf",
            "Inter-SemiBold.ttf",
            "Inter-Bold.ttf",
            "Newsreader-ExtraLight.ttf",
            "Newsreader-Light.ttf",
            "Newsreader-DisplayLight.ttf",
            "Newsreader-DisplayRegular.ttf",
            "Newsreader-Regular.ttf",
            "Newsreader-Medium.ttf",
            "Newsreader-SemiBold.ttf",
            "Newsreader-Bold.ttf",
            "Newsreader-Italic.ttf",
            "Newsreader-SemiBoldItalic.ttf"
        ]

        for file in fontFiles {
            guard let url = Bundle.main.url(forResource: file, withExtension: nil) else {
                continue
            }
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        }
    }
}
