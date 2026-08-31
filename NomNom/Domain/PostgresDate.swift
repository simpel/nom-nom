import Foundation

/// Parsing for the two date shapes PostgREST hands back.
///
/// Worth being explicit about rather than leaning on a decoder-wide strategy,
/// because the two columns are genuinely different types and want different
/// treatment: `meals.eaten_on` is a `date` with no time and no zone, while every
/// `created_at` is a `timestamptz`. One strategy cannot be right for both.
enum PostgresDate {

    // MARK: - `date` columns

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        // Deliberately the device's zone, not UTC. A `date` is a calendar day with
        // no instant attached, and the app groups meals into the user's own days —
        // parsing at UTC midnight would drop meals into the previous day for
        // anybody behind Greenwich.
        formatter.timeZone = .current
        return formatter
    }()

    /// A `date` column as local midnight.
    static func day(from string: String) -> Date {
        dayFormatter.date(from: String(string.prefix(10))) ?? Date.now
    }

    /// Local calendar day as `yyyy-MM-dd`, which is what the column wants back.
    static func string(from date: Date) -> String {
        dayFormatter.string(from: date)
    }

    // MARK: - `timestamptz` columns

    /// Postgres emits a varying number of fractional-second digits — it prints
    /// what it has, so a whole-second timestamp arrives with none at all. Trying a
    /// list of formats is less brittle than assuming a fixed width.
    private static let timestampFormats = [
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",
        "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
        "yyyy-MM-dd'T'HH:mm:ssXXXXX",
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
        "yyyy-MM-dd'T'HH:mm:ss'Z'"
    ]

    private static let timestampFormatters: [DateFormatter] = timestampFormats.map { format in
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }

    static func timestamp(from string: String) -> Date {
        for formatter in timestampFormatters {
            if let date = formatter.date(from: string) { return date }
        }
        return .now
    }
}

// MARK: - Decoding helpers

extension KeyedDecodingContainer {
    /// A `date` column decoded to local midnight.
    func decodeDay(_ key: Key) throws -> Date {
        PostgresDate.day(from: try decode(String.self, forKey: key))
    }

    /// A `timestamptz` column.
    func decodeTimestamp(_ key: Key) throws -> Date {
        PostgresDate.timestamp(from: try decode(String.self, forKey: key))
    }

    func decodeTimestampIfPresent(_ key: Key) throws -> Date? {
        guard let string = try decodeIfPresent(String.self, forKey: key) else { return nil }
        return PostgresDate.timestamp(from: string)
    }
}
