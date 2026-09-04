import SwiftUI

/// Renders a single notification item in the inbox list with dedicated designs for unread and read states.
struct NotificationRow: View {
    let notification: AppNotification
    var onTap: () -> Void
    var onDelete: () -> Void
    var onToggleRead: () -> Void

    var body: some View {
        Button(action: onTap) {
            Group {
                if notification.isUnread {
                    unreadCard
                } else {
                    readCard
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            Button(action: onToggleRead) {
                Label(
                    notification.isUnread ? "Mark Read" : "Mark Unread",
                    systemImage: notification.isUnread ? "checkmark.circle" : "circle"
                )
            }
            .tint(DS.Color.accent)
        }
        .contextMenu {
            Button(action: onToggleRead) {
                Label(
                    notification.isUnread ? "Mark as Read" : "Mark as Unread",
                    systemImage: notification.isUnread ? "checkmark.circle" : "circle"
                )
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Unread State Card

    private var unreadCard: some View {
        HStack(alignment: .center, spacing: 12) {
            // Prominent vertical accent rail
            Capsule()
                .fill(DS.Color.accent)
                .frame(width: 3.5, height: 44)

            NotificationThumbnailView(notification: notification, isUnread: true)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(DS.Color.accent)
                        .frame(width: 6, height: 6)

                    Text(notification.createdAt.formatted(.relative(presentation: .named)))
                        .font(.inter(.caption2, weight: .semibold))
                        .foregroundStyle(DS.Color.accentText)
                }

                Text(notification.title)
                    .font(.inter(.subheadline, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)

                Text(notification.body)
                    .font(.inter(.footnote))
                    .foregroundStyle(DS.Color.textPrimary.opacity(0.88))
                    .lineLimit(2)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 8)

            if notification.mealID != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DS.Color.accentText.opacity(0.85))
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 14)
        .padding(.vertical, 12)
        .background(
            ZStack {
                DS.Color.panel
                DS.Color.accentSoft.opacity(0.24)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(DS.Color.accent.opacity(0.32), lineWidth: 1)
        )
    }

    // MARK: - Read State Card

    private var readCard: some View {
        HStack(alignment: .center, spacing: 12) {
            NotificationThumbnailView(notification: notification, isUnread: false, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.inter(.subheadline, weight: .regular))
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineLimit(1)

                Text(notification.body)
                    .font(.inter(.footnote))
                    .foregroundStyle(DS.Color.textTertiary)
                    .lineLimit(2)
                    .lineSpacing(1.5)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 8)

            if notification.mealID != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(DS.Color.textTertiary.opacity(0.35))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(DS.Color.panel.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(DS.Color.line.opacity(0.15), lineWidth: 0.5)
        )
    }
}

private struct PressableCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

