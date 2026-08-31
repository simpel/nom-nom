import Foundation

extension String {
    var trimmedName: String {
        let collapsed = split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        return collapsed
    }

    /// Lowercased, accent-folded, punctuation-stripped key used to decide whether
    /// two typed names mean the same dish.
    var normalizedForMatching: String {
        let folded = folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive],
                             locale: Locale(identifier: "en_US_POSIX"))
        let cleaned = folded.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) { return Character(scalar) }
            return " "
        }
        return String(cleaned).split(separator: " ").joined(separator: " ")
    }

    /// Words of the normalized form, for token-prefix matching ("kött" matches "köttbullar").
    var matchTokens: [String] {
        SearchTokenParser.parseTokens(self)
    }
}

enum Fuzzy {
    /// Classic Levenshtein distance over Characters.
    static func distance(_ a: String, _ b: String) -> Int {
        if a == b { return 0 }
        let s = Array(a), t = Array(b)
        if s.isEmpty { return t.count }
        if t.isEmpty { return s.count }

        var previous = Array(0...t.count)
        var current = [Int](repeating: 0, count: t.count + 1)

        for i in 1...s.count {
            current[0] = i
            for j in 1...t.count {
                let cost = s[i - 1] == t[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1,        // deletion
                                 current[j - 1] + 1,     // insertion
                                 previous[j - 1] + cost) // substitution
            }
            previous = current
        }
        return previous[t.count]
    }

    /// 0...1 where 1 is identical. Used for the "did you mean" nudge.
    static func similarity(_ a: String, _ b: String) -> Double {
        let longest = max(a.count, b.count)
        guard longest > 0 else { return 1 }
        return 1 - Double(distance(a, b)) / Double(longest)
    }

    /// How close two names are allowed to be before we treat them as a probable typo
    /// of the same dish. Scales with length so "ris"/"ros" isn't flagged.
    static func isProbableTypo(_ a: String, _ b: String) -> Bool {
        guard a != b, !a.isEmpty, !b.isEmpty else { return false }
        let longest = max(a.count, b.count)
        guard longest >= 5 else { return false }
        let allowed = longest >= 9 ? 2 : 1
        return distance(a, b) <= allowed
    }
}
