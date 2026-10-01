import SwiftUI

/// One DetailHeader action, rendered as an AppButton `lg`, full width; two split the row
/// evenly. Use one `solid` action per header (the rest `soft`).
struct DetailHeaderAction {
    let title: String
    var icon: AppButtonIcon?
    var variant: DSVariant = .primary
    var appearance: DSAppearance = .solid
    var isLoading: Bool = false
    let action: () -> Void
}

/// The top of a detail screen (meal, recipe, dinner party): optional avatar and eyebrow,
/// meta line, `serif-lg` title, `sans-md` summary, fact Badges and up to two actions.
///
/// Meta sits above the title, or below it when there is an eyebrow or an avatar. Inset
/// `s2`, gap `s2`, actions `s2_5` below. Actions are `[DetailHeaderAction]` values rather
/// than a ViewBuilder so the header can enforce the `lg` / full-width / two-max rule.
///
/// ```swift
/// DetailHeader(title: "Everyone loved it", meta: "12 Mar · Taco Night", summary: note,
///              actions: [.init(title: "Rate this meal") { rate() }])
/// ```
struct DetailHeader: View {
    enum Align: Equatable { case start, center }

    let title: String
    var align: Align = .start
    var eyebrow: String?
    var meta: String?
    var summary: String?
    var avatar: Avatar?
    /// Avatar size; `xl` unless given.
    var avatarSize: AvatarSize = .xl
    /// Fact Badges (`secondary sm` by convention; an icon is allowed). Never buttons.
    var facts: [Badge] = []
    var actions: [DetailHeaderAction] = []

    private var horizontal: HorizontalAlignment { align == .center ? .center : .leading }
    private var textAlignment: TextAlignment { align == .center ? .center : .leading }
    private var metaBelowTitle: Bool { eyebrow != nil || avatar != nil }

    private var sizedAvatar: Avatar? {
        guard var avatar else { return nil }
        avatar.size = avatarSize
        return avatar
    }

    var body: some View {
        VStack(alignment: horizontal, spacing: DS.Spacing.s2_5) {
            VStack(alignment: horizontal, spacing: DS.Spacing.s2) {
                if let sizedAvatar { sizedAvatar }
                if let eyebrow {
                    SectionHeader(eyebrow, inset: false)
                        .fixedSize(horizontal: align == .center, vertical: false)
                }
                if !metaBelowTitle { metaText }
                Text(title)
                    .textStyle(.serifLg)
                    .accessibilityAddTraits(.isHeader)
                if metaBelowTitle { metaText }
                if let summary, !summary.isEmpty {
                    Text(summary).textStyle(.sansMd, tone: .secondary)
                }
                if !facts.isEmpty {
                    WrappingHStack(alignment: horizontal, spacing: DS.Spacing.s1_5, lineSpacing: DS.Spacing.s1_5) {
                        ForEach(facts.indices, id: \.self) { facts[$0] }
                    }
                }
            }
            .multilineTextAlignment(textAlignment)
            .frame(maxWidth: .infinity, alignment: align == .center ? .center : .leading)

            if !actions.isEmpty {
                HStack(spacing: DS.Spacing.s2) {
                    ForEach(actions.prefix(2).indices, id: \.self) { index in
                        let item = actions[index]
                        AppButton(
                            item.title,
                            icon: item.icon,
                            variant: item.variant,
                            appearance: item.appearance,
                            size: .lg,
                            fullWidth: true,
                            isLoading: item.isLoading,
                            action: item.action
                        )
                    }
                }
            }
        }
        .padding(.horizontal, DS.Spacing.s2)
    }

    @ViewBuilder
    private var metaText: some View {
        if let meta, !meta.isEmpty {
            Text(meta).textStyle(.sansSm, tone: .tertiary)
        }
    }
}

private struct DetailHeaderGallery: View {
    var body: some View {
        NomNomPreview(inNavigationStack: false) {
            ScrollView {
                VStack(spacing: DS.Spacing.block) {
                    DetailHeader(
                        title: "Everyone loved it",
                        meta: "12 Mar 2026 \u{00B7} Taco Night",
                        summary: "Crispy edges, a little too much lime. Leo asked for seconds.",
                        actions: [DetailHeaderAction(title: "Rate this meal") {}]
                    )
                    DetailHeader(
                        title: "Spaghetti carbonara",
                        eyebrow: "Italian",
                        meta: "Last cooked 28 Aug 2026 \u{00B7} 6 times",
                        facts: [
                            Badge("15\u{2013}30 min", icon: "clock", variant: .secondary, size: .sm),
                            Badge("Stovetop", variant: .secondary, size: .sm),
                            .rotation(.staple),
                        ],
                        actions: [DetailHeaderAction(title: "Use in a meal", icon: "plus") {}]
                    )
                    DetailHeader(
                        title: "Taco Night",
                        align: .center,
                        meta: "6 members \u{00B7} 12 followers \u{00B7} Private",
                        summary: "Fridays at ours. Bring a side.",
                        avatar: Avatar(name: "Taco Night", bucket: SupabaseConfig.partyBucket),
                        actions: [
                            DetailHeaderAction(title: "Log a meal") {},
                            DetailHeaderAction(title: "Invite", variant: .secondary, appearance: .soft) {},
                        ]
                    )
                }
                .padding(DS.Spacing.gutter)
            }
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { DetailHeaderGallery() }
#Preview("Dark") { DetailHeaderGallery().preferredColorScheme(.dark) }
