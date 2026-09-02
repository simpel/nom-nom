import SwiftUI

/// Section listing eating history of a person in PersonDetailView.
struct PersonMealHistorySection: View {
    let personName: String
    let raterRef: RaterRef
    let meals: [Meal]

    @Environment(FoodStore.self) private var store

    var body: some View {
        SectionCard("Eating History (\(meals.count))") {
            VStack(spacing: 8) {
                if meals.isEmpty {
                    Text("No meals logged with \(personName) yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                } else {
                    ForEach(meals) { meal in
                        NavigationLink {
                            MealDetailView(mealID: meal.id)
                        } label: {
                            MealRow(meal: meal, raterRef: raterRef)
                        }
                        .buttonStyle(.plain)

                        if meal.id != meals.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}
