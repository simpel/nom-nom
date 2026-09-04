import SwiftUI

/// Section displaying the meals logged for a dinner party ("What they're eating")
/// in a 2-column grid putting focus on recipe imagery.
struct PartyMealsSection: View {
    let party: Party

    @Environment(FoodStore.self) private var store

    private var partyMeals: [Meal] {
        store.meals(forParty: party.id)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("What They're Eating", horizontalPadding: 0)

            if partyMeals.isEmpty {
                SectionCard {
                    Text("No meals logged for this dinner party yet.")
                        .font(.subheadline)
                        .foregroundStyle(DS.Color.textTertiary)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(partyMeals) { meal in
                        NavigationLink {
                            MealDetailView(mealID: meal.id)
                        } label: {
                            mealGridCard(meal: meal)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func mealGridCard(meal: Meal) -> some View {
        let recipe = store.dish(meal.dishID)

        return VStack(alignment: .leading, spacing: 6) {
            RecipeImageView(
                recipe: recipe,
                photoPath: meal.photoPath,
                cuisine: recipe?.cuisine,
                cornerRadius: AppRadius.photo
            )
            .aspectRatio(1, contentMode: .fill)
            .frame(minWidth: 0, maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 2) {
                Text(store.dishName(forMeal: meal))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 4) {
                    Text(meal.eatenOn.formatted(.dateTime.day().month(.abbreviated)))
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textSecondary)

                    if let avg = store.averageReaction(forMeal: meal.id) {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(DS.Color.textTertiary)

                        Text(avg.shortLabel)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(avg.text)
                    }
                }
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            NavigationStack {
                ScrollView {
                    PartyMealsSection(party: party)
                        .padding()
                }
            }
        }
    }
}
