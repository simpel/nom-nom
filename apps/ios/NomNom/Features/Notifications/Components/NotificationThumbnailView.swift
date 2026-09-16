import SwiftUI

/// Media thumbnail for a notification row: displays meal photo/cuisine, party avatar,
/// or fallback category icon.
struct NotificationThumbnailView: View {
    let notification: AppNotification
    let isUnread: Bool
    var size: CGFloat = 48

    @Environment(FoodStore.self) private var store

    private var meal: Meal? {
        guard let id = notification.mealID else { return nil }
        return store.meal(id)
    }

    private var matchedParty: Party? {
        if let id = notification.partyID, let party = store.parties.first(where: { $0.id == id }) {
            return party
        }
        // Fallback for rows written before party_id existed.
        guard notification.kind == .partyInvite || notification.kind == .partyJoined || notification.kind == .partyFollowed else { return nil }
        return store.parties.first { notification.body.contains($0.name) }
    }

    private var likedRecipe: Recipe? {
        guard let id = notification.dishID else { return nil }
        return store.dish(id)
    }

    var body: some View {
        mediaBase
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: isUnread ? 10 : 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: isUnread ? 10 : 8, style: .continuous)
                    .strokeBorder(DS.Color.line.opacity(isUnread ? 0.35 : 0.18), lineWidth: 0.5)
            )
            .opacity(isUnread ? 1.0 : 0.8)
    }

    @ViewBuilder
    private var mediaBase: some View {
        if let meal {
            RecipeImageView(
                recipe: store.dish(meal.dishID),
                photoPath: meal.photoPaths.first,
                cuisine: store.dish(meal.dishID)?.cuisine,
                cornerRadius: isUnread ? 10 : 8
            )
        } else if let matchedParty {
            PartyAvatar(party: matchedParty, size: size)
        } else if let likedRecipe {
            RecipeImageView(
                recipe: likedRecipe,
                photoPath: likedRecipe.photoPaths.first,
                cuisine: likedRecipe.cuisine,
                cornerRadius: isUnread ? 10 : 8
            )
        } else {
            fallbackIconBase
        }
    }

    private var fallbackIconBase: some View {
        ZStack {
            RoundedRectangle(cornerRadius: isUnread ? 10 : 8, style: .continuous)
                .fill(isUnread ? DS.Color.accentSoft : DS.Color.sunken)

            Image(systemName: notification.symbol)
                .font(.system(size: size * 0.38, weight: .medium))
                .foregroundStyle(isUnread ? DS.Color.accentText : DS.Color.textSecondary)
        }
    }
}
