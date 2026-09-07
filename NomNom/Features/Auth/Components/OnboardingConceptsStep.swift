import SwiftUI

/// Explains the three core pillars of Nom Nom: Dinner Parties, Recipes, and Meals.
struct OnboardingConceptsStep: View {
    var body: some View {
        VStack(spacing: DS.Spacing.section) {
            PageHeader(
                title: "How Nom Nom Works",
                subtitle: "Three simple ideas to organize what you cook and eat together."
            )

            VStack(spacing: DS.Spacing.md) {
                conceptCard(
                    imageName: "onboarding_parties",
                    number: "01",
                    tag: "THE TABLE",
                    title: "Dinner Parties",
                    description: "Your dining collective. Connect with family, roommates, or dinner club friends to coordinate who is eating, share recipes, and learn what everyone likes."
                )

                conceptCard(
                    imageName: "onboarding_meals",
                    number: "02",
                    tag: "THE DINING LOG",
                    title: "Meals",
                    description: "Every occasion of cooking and eating. Record dates, attach food photos, track who attended, and collect honest ratings and verdicts from the table."
                )

                conceptCard(
                    imageName: "onboarding_recipes",
                    number: "03",
                    tag: "THE REPERTOIRE",
                    title: "Recipes",
                    description: "Your living cookbook. Save dishes you know and love with ingredients, instructions, tags, and effort levels so you always know what to cook."
                )
            }
        }
    }

    private func conceptCard(
        imageName: String,
        number: String,
        tag: String,
        title: String,
        description: String
    ) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo - 4, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.photo - 4, style: .continuous)
                        .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(tag)
                        .font(.caption.weight(.semibold))
                        .tracking(0.6)
                        .foregroundStyle(DS.Color.accentText)

                    Spacer()

                    Text(number)
                        .font(.caption.monospacedDigit().weight(.medium))
                        .foregroundStyle(DS.Color.textTertiary)
                }

                Text(title)
                    .font(Font.newsreader(size: 22, weight: .medium, relativeTo: .title3))
                    .foregroundStyle(DS.Color.textPrimary)

                Text(description)
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
