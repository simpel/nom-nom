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
                    RemoteMealPhoto(path: meal.photoPath, cornerRadius: 10)
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.dishName(forMeal: meal))
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        let cook = store.label(for: .account(meal.createdBy))
                        Text("\(cook.emoji) \(cook.name)")
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

            HStack(spacing: 8) {
                ForEach(Reaction.allCases) { reaction in
                    Button {
                        rate(reaction)
                    } label: {
                        VStack(spacing: 2) {
                            Text(reaction.emoji).font(.title3)
                            Text(reaction.shortLabel).font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .overlay {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(Color.secondary.opacity(0.25))
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                }

                Button {
                    decline()
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 34, height: 34)
                        .overlay {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
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
