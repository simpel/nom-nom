import Foundation

extension Calendar {
    /// Returns the beginning of the month for the given date.
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? startOfDay(for: date)
    }

    /// Weekday symbols rotated so index 0 is this locale's first day of the week.
    var orderedShortWeekdaySymbols: [String] {
        let symbols = veryShortWeekdaySymbols
        let shift = firstWeekday - 1
        guard shift > 0, shift < symbols.count else { return symbols }
        return Array(symbols[shift...] + symbols[..<shift])
    }
}
