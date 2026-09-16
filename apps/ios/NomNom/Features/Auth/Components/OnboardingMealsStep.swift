import SwiftUI

/// Onboarding step for configuring notification preferences.
struct OnboardingMealsStep: View {
    @Binding var enablePush: Bool
    @Binding var enableEmail: Bool

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            PageHeader(
                title: "Stay in the Loop",
                subtitle: "Dinner plans move fast. Turning these on means you'll never miss an invite, a menu change, or a chance to rate tonight's meal."
            )

            VStack(spacing: DS.Spacing.sm) {
                notificationCard(
                    category: "IOS NOTIFICATIONS",
                    title: "Push Notifications",
                    reason: "Receive instant alerts when someone invites you to dinner, updates the menu, or when it is time to rate tonight's meal.",
                    isOn: $enablePush
                )

                notificationCard(
                    category: "EMAIL UPDATES",
                    title: "Email Invitations",
                    reason: "Receive party invites and dinner recaps in your inbox so you never miss dinner plans even when the app is closed.",
                    isOn: $enableEmail
                )
            }

            Text("You can change these preferences at any time in Settings.")
                .font(.caption)
                .foregroundStyle(DS.Color.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.md)
        }
    }

    private func notificationCard(
        category: String,
        title: String,
        reason: String,
        isOn: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(category)
                        .font(.caption2.weight(.semibold))
                        .tracking(0.6)
                        .foregroundStyle(DS.Color.accentText)

                    Text(title)
                        .font(.headline)
                        .foregroundStyle(DS.Color.textPrimary)
                }

                Spacer()

                Toggle(title, isOn: isOn)
                    .labelsHidden()
                    .nativeToggle()
            }

            Text(reason)
                .font(.inter(.subheadline))
                .foregroundStyle(DS.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(DS.Color.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                }
        }
    }
}
