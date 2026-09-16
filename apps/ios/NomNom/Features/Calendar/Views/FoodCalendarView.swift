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
                VStack(spacing: DS.Spacing.sectionCompact) {
                    VStack(spacing: DS.Spacing.sm) {
                        monthHeader
                        weekdayHeader
                    }
                    MonthGrid(month: visibleMonth,
                              selectedDay: $selectedDay,
                              mealsByDay: mealsByDay)
                    Divider().padding(.horizontal)
                    daySection
                }
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AppButton("Today", variant: .neutral, style: .ghost, size: .sm) {
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
            Text(visibleMonth.formatted(.dateTime.year().month(.wide)))
                .font(.title2.weight(.bold))
                .foregroundStyle(DS.Color.textPrimary)

            Spacer()

            HStack(spacing: 4) {
                AppButton(systemImage: "chevron.left", variant: .neutral, style: .ghost, size: .sm) {
                    shiftMonth(by: -1)
                }

                AppButton(systemImage: "chevron.right", variant: .neutral, style: .ghost, size: .sm) {
                    shiftMonth(by: 1)
                }
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
                    .foregroundStyle(DS.Color.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Day detail

    private var daySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedDay.formatted(.dateTime.weekday(.wide).month().day()))
                .font(.headline)
                .foregroundStyle(DS.Color.textPrimary)

            VStack(spacing: 8) {
                if selectedDayMeals.isEmpty {
                    Text("No meals recorded for this day.")
                        .font(.subheadline)
                        .foregroundStyle(DS.Color.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                } else {
                    ForEach(selectedDayMeals) { meal in
                        NavigationLink {
                            MealDetailView(mealID: meal.id)
                        } label: {
                            MealRow(meal: meal)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }

                AppButton(
                    "Add meal",
                    systemImage: "plus",
                    variant: .primary,
                    style: .outlined,
                    size: .md,
                    isFullWidth: true
                ) {
                    addingForDay = selectedDay
                }
                .padding(.top, 4)
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

#Preview {
    NomNomPreview(inNavigationStack: false) {
        FoodCalendarView()
    }
}

