import SwiftUI

/// A member's highest and lowest rated dinners served in this party: one DSSection
/// each over a `Card(layout: .list)` of MealRows that open the meal.
struct PartyMemberPartyRatingsSection: View {
    let memberRef: RaterRef
    let memberName: String
    let highest: [PartyMemberMealRecord]
    let lowest: [PartyMemberMealRecord]

    var body: some View {
        if !highest.isEmpty || !lowest.isEmpty {
            VStack(alignment: .leading, spacing: DS.Spacing.block) {
                if !highest.isEmpty {
                    ratingsGroup(title: "\(memberName)\u{2019}s highest here", records: highest)
                }
                if !lowest.isEmpty {
                    ratingsGroup(title: "\(memberName)\u{2019}s lowest here", records: lowest)
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
                    .buttonStyle(ListRowButtonStyle())
                }
            }
        }
    }
}
