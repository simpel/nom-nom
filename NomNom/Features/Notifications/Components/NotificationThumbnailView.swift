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
        guard notification.kind == .partyInvite || notification.kind == .partyJoined else { return nil }
        return store.parties.first { notification.body.contains($0.name) }
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
