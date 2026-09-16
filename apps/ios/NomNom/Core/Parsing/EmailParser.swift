import Foundation
import Parsing

/// A validated, strongly-typed email address parsed via `swift-parsing`.
struct Email: RawRepresentable, Hashable, Codable, Sendable, CustomStringConvertible {
    let rawValue: String

    var description: String { rawValue }

    init?(rawValue: String) {
        guard let parsed = Self.parse(rawValue) else { return nil }
        self = parsed
    }

    init(unchecked rawValue: String) {
        self.rawValue = rawValue
    }

    /// Parses and validates a raw string into a typed `Email` using `swift-parsing`.
    static func parse(_ input: String) -> Email? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var inputSubstring = Substring(trimmed)
        do {
            let email = try EmailParser().parse(&inputSubstring)
            guard inputSubstring.isEmpty else { return nil }
            return email
        } catch {
            return nil
        }
    }
}

// MARK: - Parser Definition

/// Composable parser for RFC-compliant email strings using `swift-parsing` combinators.
struct EmailParser: Parser {
    var body: some Parser<Substring, Email> {
        Parse {
            Prefix(1...) { $0.isLetter || $0.isNumber || "._%+-".contains($0) }
            "@"
            Prefix(1...) { $0.isLetter || $0.isNumber || ".-".contains($0) }
            "."
            Prefix(2...) { $0.isLetter }
        }
        .map { (local, domain, tld) in
            Email(unchecked: "\(local)@\(domain).\(tld)".lowercased())
        }
    }
}

extension String {
    /// Validates whether this string is a valid email using `Email.parse`.
    var isValidEmail: Bool {
        Email.parse(self) != nil
    }
}
