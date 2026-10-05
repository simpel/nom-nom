import Foundation

/// Scales a free-text ingredient quantity for the recipe's servings stepper.
///
/// Understands a leading number in the forms people type: "2", "1.5", "1,5", "1/2",
/// "1 1/2", "½", "1½" and ranges "2-3" / "2–3". Anything after the number is kept
/// ("2 large" → "4 large"). Text with no leading number ("a pinch", "to taste") is
/// returned unchanged, so scaling never invents an amount.
enum QuantityScaler {

    static func scale(_ quantity: String, by factor: Double) -> String {
        let text = quantity.trimmingCharacters(in: .whitespacesAndNewlines)
        guard factor != 1, !text.isEmpty else { return text }

        // A range: scale both ends.
        for separator in ["–", "-"] {
            let parts = text.components(separatedBy: separator)
            if parts.count == 2,
               let low = parseLeading(parts[0].trimmingCharacters(in: .whitespaces)), low.rest.isEmpty,
               let high = parseLeading(parts[1].trimmingCharacters(in: .whitespaces)) {
                return "\(format(low.value * factor))\(separator)\(format(high.value * factor))\(high.rest)"
            }
        }

        guard let parsed = parseLeading(text) else { return text }
        return format(parsed.value * factor) + parsed.rest
    }

    // MARK: - Parsing

    private static let vulgarFractions: [Character: Double] = [
        "½": 0.5, "⅓": 1.0 / 3, "⅔": 2.0 / 3, "¼": 0.25, "¾": 0.75,
        "⅕": 0.2, "⅛": 0.125, "⅜": 0.375, "⅝": 0.625, "⅞": 0.875,
    ]

    /// The leading amount and whatever follows it (with its leading space kept).
    static func parseLeading(_ text: String) -> (value: Double, rest: String)? {
        let scanner = Scanner(string: text)
        scanner.charactersToBeSkipped = nil
        var value: Double?

        if let whole = scanCommaDecimal(scanner) ?? scanner.scanDouble(representation: .decimal) {
            value = whole
            // "1 1/2" or "1½"
            let afterWhole = scanner.currentIndex
            _ = scanner.scanCharacters(from: .whitespaces)
            if let fraction = scanFraction(scanner) {
                value = whole + fraction
            } else {
                scanner.currentIndex = afterWhole
                if let numerator = Optional(whole), scanner.scanString("/") != nil,
                   let denominator = scanner.scanInt(), denominator != 0 {
                    value = numerator / Double(denominator)
                }
            }
        } else if let fraction = scanFraction(scanner) {
            value = fraction
        }

        guard let value else { return nil }
        return (value, String(text[scanner.currentIndex...]))
    }

    private static func scanCommaDecimal(_ scanner: Scanner) -> Double? {
        let start = scanner.currentIndex
        guard let whole = scanner.scanInt(), scanner.scanString(",") != nil, let decimals = scanner.scanCharacters(from: .decimalDigits) else {
            scanner.currentIndex = start
            return nil
        }
        return Double("\(whole).\(decimals)")
    }

    /// "½" or "1/2" at the scanner's position.
    private static func scanFraction(_ scanner: Scanner) -> Double? {
        let start = scanner.currentIndex
        if let character = scanner.scanCharacter(), let value = vulgarFractions[character] {
            return value
        }
        scanner.currentIndex = start
        if let numerator = scanner.scanInt(), scanner.scanString("/") != nil,
           let denominator = scanner.scanInt(), denominator != 0 {
            return Double(numerator) / Double(denominator)
        }
        scanner.currentIndex = start
        return nil
    }

    // MARK: - Formatting

    private static let fractionGlyphs: [(Double, String)] = [
        (0.25, "¼"), (1.0 / 3, "⅓"), (0.5, "½"), (2.0 / 3, "⅔"), (0.75, "¾"),
    ]

    /// Whole numbers plain, common fractions as glyphs ("1½"), anything else to one
    /// decimal place ("2.4").
    static func format(_ value: Double) -> String {
        let whole = value.rounded(.down)
        let remainder = value - whole
        if remainder < 0.05 { return String(Int(whole)) }
        if remainder > 0.95 { return String(Int(whole) + 1) }
        if let glyph = fractionGlyphs.first(where: { abs($0.0 - remainder) < 0.04 })?.1 {
            return whole == 0 ? glyph : "\(Int(whole))\(glyph)"
        }
        return value.formatted(.number.precision(.fractionLength(0...1)))
    }
}
