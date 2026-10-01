// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// How an EmptyState sits in its context.
enum EmptyStateStyle: Equatable {
    /// A screen or section with nothing in it: `serif-sm` title, `sans-md`
    /// `text-secondary` message, optional AppButton below.
    case standalone
    /// Inside a SectionCard: one compact `sans-md` `text-tertiary` line
    /// ("No ratings yet"); the title is the line, the message is dropped.
    case inCard
}

/// The action under an EmptyState: an AppButton (`primary soft md` by default).
struct EmptyStateAction {
    let title: String
    var icon: AppButtonIcon?
    var variant: DSVariant = .primary
    var appearance: DSAppearance = .soft
    let perform: () -> Void
}

/// Nothing to show yet. No artwork: the arc illustrations are gone and the design
/// system hasn't defined an empty-state visual.
///
/// ```swift
/// EmptyState("No meals yet", message: "Log what you cooked tonight.",
///            action: EmptyStateAction(title: "Log a meal") { showEditor = true })
/// SectionCard("Ratings") { EmptyState("No ratings yet", style: .inCard) }
/// ```
struct EmptyState: View {
    let title: String
    var message: String?
    var action: EmptyStateAction?
    var alignment: HorizontalAlignment
    var style: EmptyStateStyle

    init(
        _ title: String,
        message: String? = nil,
        action: EmptyStateAction? = nil,
        alignment: HorizontalAlignment = .center,
        style: EmptyStateStyle = .standalone
    ) {
        self.title = title
        self.message = message
        self.action = action
        self.alignment = alignment
        self.style = style
    }

    private var textAlignment: TextAlignment {
        switch alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        default: return .center
        }
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        default: return .center
        }
    }

    var body: some View {
        switch style {
        case .standalone: standalone
        case .inCard: inCard
        }
    }

    private var standalone: some View {
        VStack(alignment: alignment, spacing: DS.Spacing.s4) {
            VStack(alignment: alignment, spacing: DS.Spacing.s1_5) {
                Text(title)
                    .textStyle(.serifSm)
                    .accessibilityAddTraits(.isHeader)
                if let message, !message.isEmpty {
                    Text(message)
                        .textStyle(.sansMd, tone: .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .multilineTextAlignment(textAlignment)
            if let action {
                AppButton(
                    action.title,
                    icon: action.icon,
                    variant: action.variant,
                    appearance: action.appearance,
                    action: action.perform
                )
            }
        }
        .padding(.vertical, DS.Spacing.s8)
        .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    private var inCard: some View {
        HStack(spacing: DS.Spacing.s3) {
            Text(title)
                .textStyle(.sansMd, tone: .tertiary)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
                .multilineTextAlignment(textAlignment)
            if let action {
                AppButton(
                    action.title,
                    icon: action.icon,
                    variant: action.variant,
                    appearance: action.appearance,
                    size: .sm,
                    action: action.perform
                )
            }
        }
    }
}

private struct EmptyStateGallery: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.block) {
                EmptyState(
                    "No meals yet",
                    message: "Log what you cooked tonight and rate it together.",
                    action: EmptyStateAction(title: "Log a meal") {}
                )
                EmptyState("Nothing matches", message: "Try a different search.", alignment: .leading)
                SectionCard("Ratings") {
                    EmptyState("No ratings yet", alignment: .leading, style: .inCard)
                }
                SectionCard("Members") {
                    EmptyState(
                        "Just you so far",
                        action: EmptyStateAction(title: "Invite") {},
                        alignment: .leading,
                        style: .inCard
                    )
                }
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}

#Preview("Light") { EmptyStateGallery() }
#Preview("Dark") { EmptyStateGallery().preferredColorScheme(.dark) }
