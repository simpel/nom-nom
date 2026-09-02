import SwiftUI

/// A meal somebody else cooked, with rating buttons right there.
struct PendingRatingCard: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store
    @State private var isSaving = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink {
                MealDetailView(mealID: meal.id)
            } label: {
                HStack(spacing: 12) {
                    RemoteMealPhoto(path: meal.photoPath, cornerRadius: AppRadius.photo)
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.dishName(forMeal: meal))
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        let cook = store.label(for: .account(meal.createdBy))
                        Text(cook.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(meal.eatenOn, format: .dateTime.day().month(.abbreviated))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 5) {
                ForEach(Reaction.allCases) { reaction in
                    Button {
                        rate(reaction)
                    } label: {
                        Text(reaction.numberLabel)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(reaction.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background {
                                RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                    .fill(reaction.fill.opacity(0.14))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                    .strokeBorder(reaction.fill.opacity(0.28), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(reaction.name)
                    .disabled(isSaving)
                }

                Button {
                    decline()
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 34, height: 34)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                .strokeBorder(Color.secondary.opacity(0.25))
                        }
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
                .accessibilityLabel("Decline")
            }
            .opacity(isSaving ? 0.4 : 1)
            .overlay {
                if isSaving { ProgressView().controlSize(.small) }
            }
        }
        .padding(.vertical, 4)
    }

    private func rate(_ reaction: Reaction) {
        isSaving = true
        Task {
            await store.rate(mealID: meal.id, as: reaction)
            isSaving = false
        }
    }

    private func decline() {
        guard let invite = store.invites(forMeal: meal.id).first(where: { $0.inviteeID == store.userID }) else { return }
        isSaving = true
        Task {
            await store.decline(invite: invite)
            isSaving = false
        }
    }
}
