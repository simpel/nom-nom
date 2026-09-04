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
                    if let photoPath = meal.photoPath {
                        RemoteMealPhoto(path: photoPath, cornerRadius: AppRadius.photo)
                            .frame(width: 46, height: 58)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                                    .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                            )
                    } else {
                        Rectangle()
                            .fill(DS.Color.sunken)
                            .frame(width: 46, height: 58)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                                    .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                            )
                            .overlay {
                                Image(systemName: "fork.knife")
                                    .font(.subheadline)
                                    .foregroundStyle(DS.Color.textTertiary)
                            }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.dishName(forMeal: meal))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            let cook = store.label(for: .account(meal.createdBy))
                            Text(cook.name)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(DS.Color.accentText)
                                .lineLimit(1)

                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(DS.Color.textTertiary)

                            Text(meal.eatenOn, format: .dateTime.day().month(.abbreviated))
                                .font(.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                ForEach(Reaction.allCases) { reaction in
                    Button {
                        rate(reaction)
                    } label: {
                        Text(reaction.numberLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(reaction.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background {
                                RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                    .fill(reaction.fill.opacity(0.12))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                    .strokeBorder(reaction.fill.opacity(0.25), lineWidth: 0.5)
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
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DS.Color.textTertiary)
                        .frame(width: 36, height: 36)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                .strokeBorder(DS.Color.line, lineWidth: 0.5)
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
