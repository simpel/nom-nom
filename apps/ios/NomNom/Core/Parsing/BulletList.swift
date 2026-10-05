import Foundation

/// A plain-text bulleted list ("• Halve the chilli\n• Serve the sauce on the side"),
/// edited the way Notes edits one: Return on a bullet starts the next bullet, Return on
/// an empty bullet ends the list. Stored as plain text so every surface (and the server)
/// reads it as written.
enum BulletList {
    static let marker = "\u{2022} "

    /// `new` after one edit of `old`, with list behaviour applied: a newline typed at the
    /// end of a bullet line gets a marker; a newline typed on an empty bullet removes it.
    static func continuing(_ old: String, into new: String) -> String {
        guard new.count == old.count + 1 else { return new }
        let prefix = zip(old, new).prefix { $0 == $1 }.count
        let insertAt = new.index(new.startIndex, offsetBy: prefix)
        guard new[insertAt] == "\n" else { return new }

        let lineStart = new[..<insertAt].lastIndex(of: "\n").map { new.index(after: $0) } ?? new.startIndex
        let line = new[lineStart..<insertAt]
        guard line.hasPrefix(marker) else { return new }

        var result = new
        if line == Substring(marker) {
            // Return on an empty bullet: end the list (drop the marker and the newline).
            result.removeSubrange(lineStart...insertAt)
        } else {
            result.insert(contentsOf: marker, at: result.index(after: insertAt))
        }
        return result
    }

    /// Bullets every non-empty line, or takes the bullets off when every line has one.
    static func toggled(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        let filled = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if filled.isEmpty { return marker }
        let allBulleted = filled.allSatisfy { $0.hasPrefix(marker) }
        return lines.map { line in
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { return line }
            if allBulleted { return String(line.dropFirst(marker.count)) }
            return line.hasPrefix(marker) ? line : marker + line
        }
        .joined(separator: "\n")
    }

    /// One bullet line per item.
    static func lines(_ items: [String]) -> [String] {
        items.map { marker + $0 }
    }
}
