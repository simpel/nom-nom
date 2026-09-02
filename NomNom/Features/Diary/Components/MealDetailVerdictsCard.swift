import SwiftUI

/// Card showing all recorded verdicts and rater profiles for a meal.
struct MealDetailVerdictsCard: View {
    let verdicts: [FoodStore.VerdictDetail]

    var body: some View {
        if !verdicts.isEmpty {
            SectionCard(title: "Ratings") {
                VStack(spacing: 8) {
                    ForEach(verdicts) { entry in
                        NavigationLink {
                            PersonDetailView(raterRef: entry.ref)
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.12))
                                        .frame(width: 32, height: 32)
                                    Text(entry.name.prefix(1).uppercased())
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Color.accentColor)
                                }

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(entry.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text("Tap for taste profile")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if let reaction = entry.reaction {
                                    HStack(spacing: 4) {
                                        Image(systemName: reaction.systemImage)
                                            .font(.system(size: 13, weight: .semibold))
                                        Text(reaction.shortLabel)
                                            .font(.subheadline.weight(.medium))
                                    }
                                    .foregroundStyle(reaction.text)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background {
                                        Capsule()
                                            .fill(reaction.fill.opacity(0.14))
                                    }
                                    .overlay {
                                        Capsule()
                                            .strokeBorder(reaction.fill.opacity(0.28), lineWidth: 1)
                                    }
                                    .accessibilityLabel(reaction.name)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let meal = store.meals.first {
            MealDetailVerdictsCard(verdicts: store.verdictDetails(forMeal: meal.id))
        }
    }
}

