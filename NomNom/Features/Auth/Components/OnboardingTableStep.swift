import SwiftUI

/// Onboarding step introducing Pillar 1: Dinner Parties (The Table) and setting up the user's first group.
struct OnboardingTableStep: View {
    @Binding var partyName: String

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            heroBanner

            SectionCard("Party Name", caption: "Optional") {
                VStack(alignment: .leading, spacing: 10) {
                    Input("Party name (e.g. Sunday Dinners)", text: $partyName)
                        .textInputAutocapitalization(.words)

                    Text("Leave blank to start solo. You can always create or join parties later.")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
        }
    }

    private var heroBanner: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Image("onboarding_parties")
                .resizable()
                .scaledToFill()
                .frame(height: 130)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo - 4, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.photo - 4, style: .continuous)
                        .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("PILLAR 01 · THE TABLE")
                        .font(.caption2.weight(.semibold))
                        .tracking(0.6)
                        .foregroundStyle(DS.Color.accentText)

                    Spacer()

                    Text("01")
                        .font(.caption.monospacedDigit().weight(.medium))
                        .foregroundStyle(DS.Color.textTertiary)
                }

                Text("Dinner Parties")
                    .font(Font.newsreader(size: 22, weight: .medium, relativeTo: .title3))
                    .foregroundStyle(DS.Color.textPrimary)

                Text("Your dining collective. Connect with family, roommates, or dinner club friends to coordinate who is eating and learn what everyone likes.")
                    .font(.inter(.subheadline))
                    .foregroundStyle(DS.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 2)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                .fill(DS.Color.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                        .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                }
        }
    }
}
