import SwiftUI

/// Onboarding step for notification preferences: a centred PageHeader and the two
/// settings as ListRow Toggle rows.
struct OnboardingMealsStep: View {
    @Binding var enablePush: Bool
    @Binding var enableEmail: Bool

    var body: some View {
        VStack(spacing: DS.Spacing.block) {
            PageHeader(
                "Stay in the loop",
                subtitle: "Turn these on so you never miss an invite, a menu change or a meal to rate.",
                align: .center
            )

            Card(layout: .list) {
                ListRow("Push notifications", meta: "Invites, menu changes, meals to rate",
                        trailing: .toggle($enablePush))
                ListRow("Email invitations", meta: "Party invites and dinner recaps",
                        trailing: .toggle($enableEmail))
            }

            Text("You can change these at any time in Settings.")
                .textStyle(.sansSm, tone: .tertiary, align: .center)
        }
    }
}
