import SwiftUI

/// Onboarding step introducing Pillar 3: Recipes (The Cookbook) and completing setup.
struct OnboardingCookbookStep: View {
    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            heroBanner

            readyCard
        }
    }

    private var heroBanner: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Image("onboarding_recipes")
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
                    Text("PILLAR 03 · THE COOKBOOK")
                        .font(.caption2.weight(.semibold))
                        .tracking(0.6)
                        .foregroundStyle(DS.Color.accentText)

                    Spacer()

                    Text("03")
                        .font(.caption.monospacedDigit().weight(.medium))
                        .foregroundStyle(DS.Color.textTertiary)
                }

                Text("Recipes & Repertoire")
                    .font(Font.newsreader(size: 22, weight: .medium, relativeTo: .title3))
                    .foregroundStyle(DS.Color.textPrimary)

                Text("Your living cookbook. Save dishes you know and love with ingredients, tags, and effort levels so you never have to wonder what to cook next.")
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

    private var readyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ready to eat?")
                .font(.headline)
                .foregroundStyle(DS.Color.textPrimary)

            Text("Your table is prepared. You can now log your first meal, invite dinner party companions, or add favorite recipes to your repertoire.")
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
