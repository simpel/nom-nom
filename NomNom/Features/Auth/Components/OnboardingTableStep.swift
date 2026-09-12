import SwiftUI

/// Onboarding step introducing Pillar 1: Dinner Parties (The Table) and setting up the user's first group.
struct OnboardingTableStep: View {
    @Binding var partyName: String

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Name your dinner party")
                    .font(Font.newsreader(size: 28, weight: .medium, relativeTo: .title))
                    .foregroundStyle(DS.Color.textPrimary)
                
                Text("You can always invite more people later.")
                    .font(.inter(.subheadline))
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, DS.Spacing.sm)

            SectionCard {
                Input("Party name (e.g. Sunday Dinners)", text: $partyName, style: .cardRow)
                    .textInputAutocapitalization(.words)
            }
        }
    }
}
