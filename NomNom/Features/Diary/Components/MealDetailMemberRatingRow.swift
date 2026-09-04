import SwiftUI

/// Single member rating row inside MealDetailPartyRatingsCard (strictly no icons).
struct MealDetailMemberRatingRow: View {
    let name: String
    var avatar: String = ""
    var initialLetter: String? = nil
    var isMe: Bool = false
    var reaction: Reaction? = nil
    var isAsked: Bool = false
    var isInviting: Bool = false
    var onTapRate: (() -> Void)? = nil
    var onAskToRate: (() -> Void)? = nil

    private let pillWidth: CGFloat = 82
    private let pillHeight: CGFloat = 28

    init(
        name: String,
        avatar: String = "",
        initialLetter: String? = nil,
        isMe: Bool = false,
        reaction: Reaction? = nil,
        isAsked: Bool = false,
        isInviting: Bool = false,
        onTapRate: (() -> Void)? = nil,
        onAskToRate: (() -> Void)? = nil
    ) {
        self.name = name
        self.avatar = avatar
        self.initialLetter = initialLetter
        self.isMe = isMe
        self.reaction = reaction
        self.isAsked = isAsked
        self.isInviting = isInviting
        self.onTapRate = onTapRate
        self.onAskToRate = onAskToRate
    }

    init(
        name: String,
        avatar: String = "",
        initialLetter: String? = nil,
        isMe: Bool = false,
        rating: MealRating?,
        isAsked: Bool = false,
        isInviting: Bool = false,
        onTapRate: (() -> Void)? = nil,
        onAskToRate: (() -> Void)? = nil
    ) {
        self.init(
            name: name,
            avatar: avatar,
            initialLetter: initialLetter,
            isMe: isMe,
            reaction: rating?.reaction,
            isAsked: isAsked,
            isInviting: isInviting,
            onTapRate: onTapRate,
            onAskToRate: onAskToRate
        )
    }

    private var displayInitial: String {
        if let initialLetter, !initialLetter.isEmpty {
            return initialLetter.prefix(1).uppercased()
        }
        return name.prefix(1).uppercased()
    }

    var body: some View {
        HStack(spacing: 12) {
            avatarView

            Text(isMe ? "You" : name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DS.Color.textPrimary)
                .lineLimit(1)

            Spacer()

            trailingAction
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(isMe ? DS.Color.accentSoft : DS.Color.sunken)
                .frame(width: 34, height: 34)

            let cleanAvatar = avatar.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanAvatar.isEmpty {
                Text(cleanAvatar)
                    .font(.system(size: 18))
            } else {
                Text(displayInitial)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isMe ? DS.Color.accentText : DS.Color.textPrimary)
            }
        }
    }

    @ViewBuilder
    private var trailingAction: some View {
        if let reaction {
            pill(
                title: reaction.shortLabel,
                textColor: reaction.text,
                fillColor: reaction.fill.opacity(0.16),
                strokeColor: reaction.fill.opacity(0.32),
                action: isMe ? onTapRate : nil
            )
            .accessibilityLabel(reaction.name)
        } else if isMe {
            pill(
                title: "Rate",
                textColor: DS.Color.accentText,
                fillColor: DS.Color.accentSoft,
                strokeColor: DS.Color.accent.opacity(0.32),
                action: onTapRate
            )
        } else if isAsked {
            pill(
                title: "Asked",
                textColor: DS.Color.textSecondary,
                fillColor: DS.Color.sunken,
                strokeColor: DS.Color.line.opacity(0.5)
            )
        } else if let onAskToRate {
            pill(
                title: "Ask to rate",
                textColor: DS.Color.accentText,
                fillColor: DS.Color.accentSoft,
                strokeColor: DS.Color.accent.opacity(0.32),
                isLoading: isInviting,
                action: onAskToRate
            )
        } else {
            pill(
                title: "Unrated",
                textColor: DS.Color.textTertiary,
                fillColor: DS.Color.sunken,
                strokeColor: DS.Color.line.opacity(0.35)
            )
        }
    }

    @ViewBuilder
    private func pill(
        title: String,
        textColor: Color,
        fillColor: Color,
        strokeColor: Color,
        isLoading: Bool = false,
        action: (() -> Void)? = nil
    ) -> some View {
        let badge = HStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .controlSize(.mini)
            } else {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(width: pillWidth, height: pillHeight)
        .background(Capsule().fill(fillColor))
        .overlay(Capsule().strokeBorder(strokeColor, lineWidth: 1))

        if let action {
            Button(action: action) {
                badge
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        } else {
            badge
        }
    }
}

#Preview("Member Rating States") {
    VStack(spacing: 12) {
        MealDetailMemberRatingRow(
            name: "Joel Sandén",
            avatar: "🧑‍🍳",
            isMe: true,
            reaction: .great,
            onTapRate: {}
        )
        MealDetailMemberRatingRow(
            name: "Joel Sandén",
            avatar: "🧑‍🍳",
            isMe: true,
            reaction: nil,
            onTapRate: {}
        )
        MealDetailMemberRatingRow(
            name: "Alice Lind",
            avatar: "👩‍🌾",
            isMe: false,
            reaction: .good
        )
        MealDetailMemberRatingRow(
            name: "Bob Berg",
            avatar: "🧑",
            isMe: false,
            reaction: nil,
            isAsked: true
        )
        MealDetailMemberRatingRow(
            name: "Charlie Stone",
            avatar: "👨‍🍳",
            isMe: false,
            reaction: nil,
            isAsked: false,
            onAskToRate: {}
        )
        MealDetailMemberRatingRow(
            name: "Leo",
            avatar: "👦",
            isMe: false,
            reaction: .amazing
        )
    }
    .padding()
    .background(DS.Color.panel)
    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
    .padding()
}
