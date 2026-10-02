import SwiftUI

/// "What they're eating": the party's meals as a two-column grid of PhotoCard `md`
/// tiles with their verdict Badge, dish name and date. Empty, an EmptyState `card`.
struct PartyMealsSection: View {
    let party: Party

    @Environment(FoodStore.self) private var store

    private var partyMeals: [Meal] {
        store.meals(forParty: party.id)
    }

    private let columns = [
        GridItem(.flexible(), spacing: DS.Spacing.s3, alignment: .top),
        GridItem(.flexible(), spacing: DS.Spacing.s3, alignment: .top),
    ]

    private var countText: String? {
        guard !partyMeals.isEmpty else { return nil }
        return partyMeals.count == 1 ? "1 meal" : "\(partyMeals.count) meals"
    }

    var body: some View {
        if partyMeals.isEmpty {
            DSSection("What they\u{2019}re eating") {
                EmptyState("No meals yet", message: "Meals served to this party will show up here.")
            }
        } else {
            DSSection("What they\u{2019}re eating", trailing: countText) {
                LazyVGrid(columns: columns, spacing: DS.Spacing.s4) {
                    ForEach(partyMeals) { meal in
                        NavigationLink {
                            MealDetailView(mealID: meal.id)
                        } label: {
                            tile(for: meal)
                        }
                        .buttonStyle(AppPressableButtonStyle())
                    }
                }
            }
        }
    }

    private func tile(for meal: Meal) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            PhotoCard(
                .meal(meal),
                size: .md,
                fillsWidth: true,
                badge: store.averageScore(forMeal: meal.id).map { .score($0) }
            )

            VStack(alignment: .leading, spacing: DS.Spacing.s0_5) {
                Text(store.dishName(forMeal: meal))
                    .textStyle(.sansMd, weight: .semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(meal.eatenOn.formatted(.dateTime.day().month(.abbreviated)))
                    .textStyle(.sansSm, tone: .tertiary)
                    .lineLimit(1)
            }
            .padding(.horizontal, DS.Spacing.s1)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            NavigationStack {
                ScrollView {
                    PartyMealsSection(party: party)
                        .padding(DS.Spacing.gutter)
                }
            }
        }
    }
}
