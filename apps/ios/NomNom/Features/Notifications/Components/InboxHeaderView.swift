import SwiftUI

/// Header card for the notifications inbox, displaying the Newsreader page title,
/// unread count capsule, and contextual subtitle.
struct InboxHeaderView: View {
    let unreadCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("Inbox")
                    .font(AppTypography.pageTitleFont)
                    .foregroundStyle(DS.Color.textPrimary)

                if unreadCount > 0 {
                    Text("\(unreadCount) unread")
                        .font(.inter(.caption, weight: .semibold))
                        .foregroundStyle(DS.Color.accentText)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(DS.Color.accentSoft)
                        .clipShape(Capsule())
                }

                Spacer()
            }

            Text(headerSubtitle)
                .font(.inter(.subheadline))
                .foregroundStyle(DS.Color.textSecondary)
        }
        .padding(.horizontal, DS.Spacing.screenHorizontal)
        .padding(.top, 4)
        .padding(.bottom, DS.Spacing.xs)
    }

    private var headerSubtitle: String {
        if unreadCount > 0 {
            return "\(unreadCount) unread \(unreadCount == 1 ? "notification" : "notifications") requiring your attention."
        } else if totalCount == 0 {
            return "Invitations, meal ratings, and party updates will appear here."
        } else {
            return "All caught up on dinner party invites and ratings."
        }
    }
}
