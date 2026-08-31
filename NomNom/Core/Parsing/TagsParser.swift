import Foundation
import Parsing

/// Parses comma-separated lists of tags or keywords into a normalized array of strings.
enum TagsParser {
    private static let singleTagParser = Parse(input: Substring.self) {
        Whitespace(.horizontal)
        Prefix { $0 != "," && !$0.isNewline }
        Whitespace(.horizontal)
    }.map { (tag: Substring) -> String in
        tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static let listParser = Many {
        singleTagParser
    } separator: {
        ","
    }

    /// Parses a comma-delimited string (e.g. "pasta, quick, italian") into cleaned, lowercased tags.
    static func parse(_ input: String) -> [String] {
        var substring = Substring(input)
        guard let tags = try? listParser.parse(&substring) else {
            return input
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        }
        return tags.filter { !$0.isEmpty }
    }
}
