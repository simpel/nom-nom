import SwiftUI

/// Final onboarding step for setting up the user's first dinner party or starting solo.
struct OnboardingPartyStep: View {
    @Binding var partyName: String

    var body: some View {
        VStack(spacing: DS.Spacing.section) {
            PageHeader(
                title: "Your First Dinner Party",
                subtitle: "Set up a group for your household or friends, or choose to start on your own."
            )

            SectionCard("Party Name", caption: "Optional") {
                VStack(alignment: .leading, spacing: 10) {
                    Input("Party name (e.g. Family Dinners)", text: $partyName)
                        .textInputAutocapitalization(.words)

                    Text("You can invite members with a link or email as soon as you are in.")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
        }
    }
}
