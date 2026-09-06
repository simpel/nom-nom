import SwiftUI

/// Section displaying previous occasions where this dinner party had the same recipe.
struct MealDetailHistoryCard: View {
    let history: [Meal]
    var partyName: String? = nil

    @Environment(FoodStore.self) private var store

    private var sectionTitle: String {
        if let partyName, !partyName.isEmpty, partyName != "You" {
            return "Past meals with \(partyName)"
        }
        return "Past occasions with this recipe"
    }

    var body: some View {
        if !history.isEmpty {
            SectionCard(title: sectionTitle) {
                VStack(spacing: 8) {
                    ForEach(history.prefix(8)) { past in
                        NavigationLink {
                            MealDetailView(mealID: past.id)
                        } label: {
                            rowContent(for: past)
                        }
                        .buttonStyle(.plain)

                        if past.id != history.prefix(8).last?.id {
                            Divider().overlay(DS.Color.line.opacity(0.3))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func rowContent(for past: Meal) -> some View {
        HStack(spacing: 12) {
            if let photo = past.photoPath {
                RemoteMealPhoto(path: photo, cornerRadius: AppRadius.photo)
                    .frame(width: 44, height: 44)
            } else {
                RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                    .fill(DS.Color.sunken)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(past.eatenOn, format: .dateTime.day().month(.abbreviated).year())
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DS.Color.textPrimary)

                Text(past.createdBy == store.userID ? "Cooked by you" : "Cooked by \(store.label(for: .account(past.createdBy)).name)")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            Spacer()

            if let score = store.averageScore(forMeal: past.id),
               let reaction = store.averageReaction(forMeal: past.id) {
                ScoreBadge(score: score, reaction: reaction, format: .scoreOnly, size: .sm)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
        }
        .padding(.vertical, 3)
    }
}
