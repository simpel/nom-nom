import SwiftUI

/// Tab 2 — month grid of what we ate, day by day.
struct FoodCalendarView: View {
    @Environment(FoodStore.self) private var store

    @State private var visibleMonth: Date = Calendar.current.startOfMonth(for: .now)
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: .now)
    @State private var addingForDay: Date?

    private let calendar = Calendar.current

    /// Meals keyed by their day, so a lookup per cell is O(1).
    private var mealsByDay: [Date: [Meal]] {
        Dictionary(grouping: store.myMeals) { calendar.startOfDay(for: $0.eatenOn) }
    }

    private var selectedDayMeals: [Meal] {
        (mealsByDay[calendar.startOfDay(for: selectedDay)] ?? []).sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    monthHeader
                    weekdayHeader
                    MonthGrid(month: visibleMonth,
                              selectedDay: $selectedDay,
                              mealsByDay: mealsByDay)
                    Divider().padding(.horizontal)
                    daySection
                }
                .padding(.vertical)
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Today") {
                        withAnimation(.snappy) {
                            visibleMonth = calendar.startOfMonth(for: .now)
                            selectedDay = calendar.startOfDay(for: .now)
                        }
                    }
                }
            }
            .sheet(isPresented: Binding(get: { addingForDay != nil },
                                        set: { if !$0 { addingForDay = nil } })) {
                MealEditorView(mealID: nil, initialDate: addingForDay)
            }
        }
    }

    // MARK: - Header

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .padding(8)
            }

            Spacer()

            Text(visibleMonth, format: .dateTime.month(.wide).year())
                .font(.title3.weight(.semibold))
                .contentTransition(.numericText())

            Spacer()

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .padding(8)
            }
        }
        .padding(.horizontal)
    }

    private var weekdayHeader: some View {
        let symbols = calendar.orderedShortWeekdaySymbols
        return HStack(spacing: 4) {
            ForEach(Array(symbols.enumerated()), id: \.offset) { indexed in
                Text(indexed.element)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Selected day

    private var daySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedDay, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.headline)
                Spacer()
                Button {
                    addingForDay = selectedDay
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline)
                }
            }

            if selectedDayMeals.isEmpty {
                Text("Nothing logged for this day.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(selectedDayMeals) { meal in
                    NavigationLink {
                        MealDetailView(mealID: meal.id)
                    } label: {
                        HStack(spacing: 12) {
                            RemoteMealPhoto(path: meal.photoPath, cornerRadius: 10)
                                .frame(width: 64, height: 64)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.dishName(forMeal: meal))
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                let verdicts = store.verdictEntries(forMeal: meal.id)
                                if !verdicts.isEmpty {
                                    VerdictStrip(entries: verdicts)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(10)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.secondary.opacity(0.08))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }

    private func shiftMonth(by months: Int) {
        guard let next = calendar.date(byAdding: .month, value: months, to: visibleMonth) else { return }
        withAnimation(.snappy(duration: 0.2)) {
            visibleMonth = calendar.startOfMonth(for: next)
        }
    }
}
