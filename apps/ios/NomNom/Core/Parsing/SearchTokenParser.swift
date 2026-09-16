import Foundation
import Parsing

/// Parses and normalizes text into matching tokens for search and dish queries.
enum SearchTokenParser {
    private static let tokenParser = Parse(input: Substring.self) {
        Whitespace(.horizontal)
        Prefix(1...) { !$0.isWhitespace }
    }.map { (token: Substring) -> String in
        token.lowercased()
    }

    private static let tokenSequenceParser = Many {
        tokenParser
    }

    /// Extracts normalized search tokens from an input query.
    static func parseTokens(_ input: String) -> [String] {
        let normalized = input.normalizedForMatching
        var substring = Substring(normalized)
        guard let tokens = try? tokenSequenceParser.parse(&substring) else {
            return normalized.split(separator: " ").map(String.init)
        }
        return tokens.filter { !$0.isEmpty }
    }
}
