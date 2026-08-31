import SwiftUI

/// One row in the diary log list.
struct MealRow: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private var relativeDate: String {
        Self.relativeFormatter.localizedString(for: meal.eatenOn, relativeTo: .now)
    }

    var body: some View {
        HStack(spacing: 12) {
            RemoteMealPhoto(path: meal.photoPath, cornerRadius: 10)
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(store.dishName(forMeal: meal))
                    .font(.body.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(meal.eatenOn, format: .dateTime.day().month(.abbreviated))
                    Text("·")
                    Text(relativeDate)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                let verdicts = store.verdictEntries(forMeal: meal.id)
                if !verdicts.isEmpty {
                    VerdictStrip(entries: verdicts)
                }

                let servedParties = store.parties(forMeal: meal.id)
                if !servedParties.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                        Text(servedParties.map(\.name).joined(separator: ", "))
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
