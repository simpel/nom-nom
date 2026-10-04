import SwiftUI

/// One ScreenHeader action: an AppButton `md`, label only. There is no icon and no
/// width option: header buttons hug their label (components/ScreenHeader/README.md).
struct ScreenHeaderAction {
    let title: String
    var variant: DSVariant = .primary
    var appearance: DSAppearance = .solid
    var isLoading: Bool = false
    let action: () -> Void
}

/// Which kind of screen a ScreenHeader opens. It decides alignment; there is no free `align`.
/// - `standard`: detail screens and sheets. Leading (centred only by an avatar).
/// - `tabRoot`: Meals, Recipes, Parties. Centred, with a one-sentence summary.
/// - `moment`: a full-screen flow outside the tab bar (sign-in, onboarding, the Pro paywall). Centred.
enum ScreenHeaderRole: Equatable { case standard, tabRoot, moment }

/// The top of every screen and sheet (components/ScreenHeader/README.md): avatar,
/// eyebrow, `serif-lg` title, date, one sentence and up to two actions, in that order.
///
/// - Centred when there is an `avatar` or the `role` is `.tabRoot` or `.moment`; otherwise
///   leading. There is no `align`.
/// - `eyebrow`: ONE item, a category ("Italian") or the context it lives in ("The Friday
///   Feast Club"). Never two joined, never a date, product or flow name.
/// - `date`: formatted here, "Sunday 4 October", with the year only when it isn't this year.
/// - `actions`: at most two, at most one `solid`, on one row `spacing-2` apart.
/// - Spacing: avatar to text `s4`; eyebrow, title, date and summary `s2` apart; `s4` before
///   the actions.
///
/// ```swift
/// ScreenHeader(meal.title, eyebrow: party.name, date: meal.date,
///              actions: [.init(title: "Rate this meal") { rate() }])
/// ScreenHeader(party.name, summary: party.about, avatar: Avatar(party: party))
/// ScreenHeader("Meals", summary: "…", role: .tabRoot, actions: [.init(title: "Log a meal") { log() }])
/// ScreenHeader("Cook with the whole picture", summary: "…", role: .moment)
/// ```
struct ScreenHeader: View {
    let title: String
    var eyebrow: String?
    var date: Date?
    var summary: String?
    var avatar: Avatar?
    var role: ScreenHeaderRole
    var actions: [ScreenHeaderAction]

    init(
        _ title: String,
        eyebrow: String? = nil,
        date: Date? = nil,
        summary: String? = nil,
        avatar: Avatar? = nil,
        role: ScreenHeaderRole = .standard,
        actions: [ScreenHeaderAction] = []
    ) {
        self.title = title
        self.eyebrow = eyebrow
        self.date = date
        self.summary = summary
        self.avatar = avatar
        self.role = role
        self.actions = Array(actions.prefix(2))
    }

    private var centred: Bool { avatar != nil || role != .standard }
    private var horizontal: HorizontalAlignment { centred ? .center : .leading }
    private var frameAlignment: Alignment { centred ? .center : .leading }
    private var textAlign: TextAlignment { centred ? .center : .leading }

    /// The header's avatar is always `xl`.
    private var sizedAvatar: Avatar? {
        guard var avatar else { return nil }
        avatar.size = .xl
        return avatar
    }

    var body: some View {
        VStack(alignment: horizontal, spacing: DS.Spacing.s4) {
            if let sizedAvatar { sizedAvatar }
            VStack(alignment: horizontal, spacing: DS.Spacing.s2) {
                if let eyebrow, !eyebrow.isEmpty {
                    SectionHeader(title: eyebrow)
                        .fixedSize(horizontal: centred, vertical: false)
                }
                Text(title)
                    .textStyle(.serifLg, align: textAlign)
                    .accessibilityAddTraits(.isHeader)
                if let date {
                    Text(Self.format(date))
                        .textStyle(.sansSm, tone: .tertiary, align: textAlign)
                }
                if let summary, !summary.isEmpty {
                    Text(summary)
                        .textStyle(.sansMd, tone: .secondary, align: textAlign)
                        .frame(maxWidth: DS.Container.sm, alignment: frameAlignment)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if !actions.isEmpty {
                HStack(spacing: DS.Spacing.s2) {
                    ForEach(actions.indices, id: \.self) { index in
                        let item = actions[index]
                        AppButton(
                            item.title,
                            variant: item.variant,
                            appearance: item.appearance,
                            size: .md,
                            isLoading: item.isLoading,
                            action: item.action
                        )
                        .fixedSize()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    /// "Sunday 4 October"; the year is added only when it isn't the current one.
    static func format(_ date: Date, now: Date = .now) -> String {
        let calendar = Calendar.current
        var dayMonth = Date.FormatStyle.dateTime.day().month(.wide)
        if calendar.component(.year, from: date) != calendar.component(.year, from: now) {
            dayMonth = dayMonth.year()
        }
        // Weekday and the rest joined with a space: the locale's combined style adds a comma.
        return "\(date.formatted(.dateTime.weekday(.wide))) \(date.formatted(dayMonth))"
    }
}

private struct ScreenHeaderGallery: View {
    var body: some View {
        NomNomPreview(inNavigationStack: false) {
            ScrollView {
                VStack(spacing: DS.Spacing.block) {
                    ScreenHeader("Meals", summary: "What you've cooked and what's left to rate.",
                                 role: .tabRoot, actions: [.init(title: "Log a meal") {}])
                    ScreenHeader(
                        "Double Smash Burgers with Secret Sauce",
                        eyebrow: "The Friday Feast Club",
                        date: .now,
                        actions: [.init(title: "Rate this meal") {}]
                    )
                    ScreenHeader(
                        "Double Smash Burgers with Secret Sauce",
                        eyebrow: "American",
                        actions: [
                            .init(title: "Start cooking") {},
                            .init(title: "Use in a meal", variant: .secondary, appearance: .soft) {},
                        ]
                    )
                    ScreenHeader(
                        "The Friday Feast Club",
                        summary: "A weekly gathering of home cooks, every Friday night.",
                        avatar: Avatar(name: "The Friday Feast Club", bucket: SupabaseConfig.partyBucket),
                        actions: [.init(title: "Add meal") {}]
                    )
                    ScreenHeader("Cook with the whole picture",
                                 summary: "Trends, party scores and unlimited photos.", role: .moment)
                }
                .padding(DS.Spacing.gutter)
            }
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { ScreenHeaderGallery() }
#Preview("Dark") { ScreenHeaderGallery().preferredColorScheme(.dark) }
