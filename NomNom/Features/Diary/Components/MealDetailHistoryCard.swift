import SwiftUI

/// Section displaying previous servings/history of the same dish.
struct MealDetailHistoryCard: View {
    let history: [Meal]

    @Environment(FoodStore.self) private var store

    var body: some View {
        if !history.isEmpty {
            SectionCard(title: "Other times we've had this") {
                VStack(spacing: 8) {
                    ForEach(history.prefix(8)) { past in
                        NavigationLink {
                            MealDetailView(mealID: past.id)
                        } label: {
                            HStack(spacing: 10) {
                                RemoteMealPhoto(path: past.photoPath, cornerRadius: AppRadius.photo)
                                    .frame(width: 44, height: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(past.eatenOn, format: .dateTime.day().month(.abbreviated).year())
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    let pastParties = store.parties(forMeal: past.id)
                                    if !pastParties.isEmpty {
                                        Text(pastParties.map(\.name).joined(separator: ", "))
                                            .font(.caption2)
                                    }
                                }
                                Spacer()
                        
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)

                        if past.id != history.prefix(8).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}
