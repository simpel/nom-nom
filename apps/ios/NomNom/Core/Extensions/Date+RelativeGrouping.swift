import Foundation

private enum RelativeDateSectionKey: Hashable, Comparable {
    case today
    case yesterday
    case previous7Days
    case previous30Days
    case month(year: Int, month: Int, startOfMonth: Date)

    var sortOrder: (Int, Double) {
        switch self {
        case .today: return (0, 0)
        case .yesterday: return (1, 0)
        case .previous7Days: return (2, 0)
        case .previous30Days: return (3, 0)
        case .month(_, _, let startOfMonth):
            return (4, -startOfMonth.timeIntervalSince1970)
        }
    }

    static func < (lhs: RelativeDateSectionKey, rhs: RelativeDateSectionKey) -> Bool {
        let l = lhs.sortOrder
        let r = rhs.sortOrder
        if l.0 != r.0 { return l.0 < r.0 }
        return l.1 < r.1
    }

    func title(currentYear: Int) -> String {
        switch self {
        case .today:
            return "Today"
        case .yesterday:
            return "Yesterday"
        case .previous7Days:
            return "Previous 7 Days"
        case .previous30Days:
            return "Previous 30 Days"
        case .month(let year, _, let startOfMonth):
            let formatter = DateFormatter()
            if year == currentYear {
                formatter.setLocalizedDateFormatFromTemplate("MMMM")
            } else {
                formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
            }
            return formatter.string(from: startOfMonth)
        }
    }
}

extension Array where Element == Meal {
    /// Groups meals into relative time buckets inspired by Apple Notes:
    /// - "Today"
    /// - "Yesterday"
    /// - "Previous 7 Days"
    /// - "Previous 30 Days"
    /// - Month names (e.g., "July", "April" for current year; "December 2025" for past years)
    func groupedByRelativeDate(calendar: Calendar = .current, now: Date = .now) -> [(title: String, meals: [Meal])] {
        let today = calendar.startOfDay(for: now)
        let currentYear = calendar.component(.year, from: now)

        var buckets: [RelativeDateSectionKey: [Meal]] = [:]

        for meal in self {
            let startOfEaten = calendar.startOfDay(for: meal.eatenOn)
            let daysAgo = calendar.dateComponents([.day], from: startOfEaten, to: today).day ?? 0

            let key: RelativeDateSectionKey
            if daysAgo <= 0 {
                key = .today
            } else if daysAgo == 1 {
                key = .yesterday
            } else if daysAgo < 7 {
                key = .previous7Days
            } else if daysAgo < 30 {
                key = .previous30Days
            } else {
                let year = calendar.component(.year, from: meal.eatenOn)
                let month = calendar.component(.month, from: meal.eatenOn)
                let monthStart = calendar.startOfMonth(for: meal.eatenOn)
                key = .month(year: year, month: month, startOfMonth: monthStart)
            }

            buckets[key, default: []].append(meal)
        }

        let sortedKeys = buckets.keys.sorted()
        return sortedKeys.map { key in
            (title: key.title(currentYear: currentYear), meals: buckets[key] ?? [])
        }
    }

    /// Groups meals by calendar week for the Meals list ("Nom Nom iOS" canvas):
    /// "This week", "Last week", then one bucket per month ("September", or
    /// "December 2025" for past years). Newest bucket first; meals keep their order.
    func groupedByWeek(calendar: Calendar = .current, now: Date = .now) -> [(title: String, meals: [Meal])] {
        let currentYear = calendar.component(.year, from: now)
        guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
              let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeek) else {
            return [(title: "Meals", meals: self)]
        }

        var order: [String] = []
        var buckets: [String: [Meal]] = [:]
        let formatter = DateFormatter()

        for meal in sorted(by: { $0.eatenOn > $1.eatenOn }) {
            let title: String
            if meal.eatenOn >= thisWeek {
                title = "This week"
            } else if meal.eatenOn >= lastWeek {
                title = "Last week"
            } else {
                let year = calendar.component(.year, from: meal.eatenOn)
                formatter.setLocalizedDateFormatFromTemplate(year == currentYear ? "MMMM" : "MMMM yyyy")
                title = formatter.string(from: meal.eatenOn)
            }
            if buckets[title] == nil { order.append(title) }
            buckets[title, default: []].append(meal)
        }
        return order.map { (title: $0, meals: buckets[$0] ?? []) }
    }
}
