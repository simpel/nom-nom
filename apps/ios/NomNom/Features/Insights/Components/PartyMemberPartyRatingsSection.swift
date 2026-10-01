import SwiftUI

/// Section displaying an individual member's highest and lowest rated dinners served in this party,
/// reusing the canonical startpage meal row component (`MealRow`).
struct PartyMemberPartyRatingsSection: View {
    let memberRef: RaterRef
    let memberName: String
    let highest: [PartyMemberMealRecord]
    let lowest: [PartyMemberMealRecord]

    var body: some View {
        if !highest.isEmpty || !lowest.isEmpty {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text("\(memberName)'s Party Ratings")
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)

                VStack(spacing: DS.Spacing.md) {
                    if !highest.isEmpty {
                        ratingsGroup(title: "Highest in this party", records: highest)
                    }

                    if !lowest.isEmpty {
                        ratingsGroup(title: "Lowest in this party", records: lowest)
                    }
                }
            }
        }
    }

    private func ratingsGroup(title: String, records: [PartyMemberMealRecord]) -> some View {
        DSSection(title) {
            Card(layout: .list) {
                ForEach(records) { record in
                    NavigationLink {
                        MealDetailView(mealID: record.meal.id)
                    } label: {
                        MealRow(meal: record.meal, raterRef: memberRef, isMinimal: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
