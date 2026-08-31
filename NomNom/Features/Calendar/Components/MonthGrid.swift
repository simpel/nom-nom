import SwiftUI

struct MonthGrid: View {
    let month: Date
    @Binding var selectedDay: Date
    let mealsByDay: [Date: [Meal]]

    @Environment(FoodStore.self) private var store

    private let calendar = Calendar.current

    /// Leading blanks + every day of the month, padded to whole weeks.
    private var cells: [Date?] {
        let start = calendar.startOfMonth(for: month)
        guard let range = calendar.range(of: .day, in: .month, for: start) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: start)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7

        var result: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<range.count {
            result.append(calendar.date(byAdding: .day, value: offset, to: start))
        }
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
            ForEach(Array(cells.enumerated()), id: \.offset) { indexed in
                if let day = indexed.element {
                    let meals = mealsByDay[calendar.startOfDay(for: day)] ?? []
                    DayCell(day: day,
                            photoPath: meals.first { $0.photoPath != nil }?.photoPath,
                            mealCount: meals.count,
                            moodTint: mood(of: meals),
                            dishNames: meals.map { store.dishName(forMeal: $0) },
                            isSelected: calendar.isDate(day, inSameDayAs: selectedDay),
                            isToday: calendar.isDateInToday(day))
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.15)) {
                                selectedDay = calendar.startOfDay(for: day)
                            }
                        }
                } else {
                    Color.clear.frame(height: 52)
                }
            }
        }
        .padding(.horizontal, 12)
    }

    /// Colour of the little dots under the date: how the day went overall.
    private func mood(of meals: [Meal]) -> Color? {
        guard !meals.isEmpty else { return nil }
        let scores = meals.compactMap { store.averageScore(forMeal: $0.id) }
        guard !scores.isEmpty else { return .gray }
        let average = scores.reduce(0, +) / Double(scores.count)
        if average >= 0.7 { return .green }
        if average >= 0.34 { return .orange }
        return .red
    }
}
