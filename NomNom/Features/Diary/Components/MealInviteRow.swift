import SwiftUI

/// One invited person row, displaying their name/email and invite status chip.
struct MealInviteRow: View {
    let invite: MealInvite

    @Environment(FoodStore.self) private var store

    var body: some View {
        HStack(spacing: 10) {
            if let id = invite.inviteeID {
                let who = store.label(for: .account(id))
                Text(who.emoji)
                Text(who.name)
            } else {
                Text("✉️")
                Text(invite.inviteeEmail ?? "Someone")
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            statusChip
        }
        .font(.subheadline)
    }

    @ViewBuilder
    private var statusChip: some View {
        if invite.isUnclaimed {
            Chip(text: "No account yet", systemImage: "clock", tint: .secondary)
        } else if store.ratings(forMeal: invite.mealID).contains(where: { $0.raterID == invite.inviteeID }) {
            Chip(text: "Rated", systemImage: "checkmark.circle.fill", tint: .green)
        } else {
            switch invite.status {
            case .declined:
                Chip(text: "Declined", systemImage: "xmark.circle", tint: .red)
            case .accepted, .pending:
                Chip(text: "Waiting", systemImage: "hourglass", tint: .orange)
            }
        }
    }
}

typealias InviteRow = MealInviteRow
