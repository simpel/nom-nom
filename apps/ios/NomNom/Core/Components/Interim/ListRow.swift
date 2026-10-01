// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// One row in a `Card(layout: .list)`: an optional leading slot (Avatar, photo
/// thumbnail or rank), a `sans-md` title over up to two `sans-sm` meta lines, and
/// trailing slots (Badge, ScoreValue `xs`, AppButton, Toggle, chevron, value).
/// At least `rowMin` tall. With `action` the whole row is one button.
///
/// ```swift
/// Card(layout: .list) {
///     ListRow("Spaghetti carbonara", meta: "Household · 30 min",
///             leading: .photo(.meal(meal)), trailing: .score(0.82), .chevron)
///     ListRow("Cuisine", trailing: .value("Italian"))
///     ListRow("Make party public", trailing: .toggle($isPublic))
/// }
/// ```
struct ListRow: View {
    let title: String
    var meta: String?
    var detail: String?
    var metaTone: DS.Tone
    /// Overrides `metaTone` with a role ink (e.g. `DS.Color.destructiveText` for an error).
    var metaColor: Color?
    var detailLineLimit: Int
    var emphasized: Bool
    var leading: ListRowLeading
    var trailing: [ListRowTrailing]
    var action: (() -> Void)?

    /// - Parameters:
    ///   - meta: First meta line (`sans-sm`, `metaTone`, one line).
    ///   - detail: Second meta line (`sans-sm` tertiary, `detailLineLimit` lines).
    ///   - emphasized: Title semibold (unread, current item).
    init(
        _ title: String,
        meta: String? = nil,
        detail: String? = nil,
        metaTone: DS.Tone = .tertiary,
        metaColor: Color? = nil,
        detailLineLimit: Int = 1,
        emphasized: Bool = false,
        leading: ListRowLeading = .none,
        trailing: ListRowTrailing...,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.meta = meta
        self.detail = detail
        self.metaTone = metaTone
        self.metaColor = metaColor
        self.detailLineLimit = detailLineLimit
        self.emphasized = emphasized
        self.leading = leading
        self.trailing = trailing
        self.action = action
    }

    var body: some View {
        if let action {
            Button(action: action) { content }
                .buttonStyle(AppPressableButtonStyle())
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: DS.Spacing.s3) {
            ListRowLeadingView(slot: leading)

            VStack(alignment: .leading, spacing: DS.Spacing.s0_5) {
                Text(title)
                    .textStyle(.sansMd, weight: emphasized ? .semibold : nil)
                    .lineLimit(1)
                if let meta, !meta.isEmpty {
                    Text(meta)
                        .textStyle(.sansSm, tone: metaColor == nil ? metaTone : nil)
                        .foregroundStyle(metaColor ?? metaTone.color)
                        .lineLimit(1)
                }
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .textStyle(.sansSm, tone: .tertiary)
                        .lineLimit(detailLineLimit)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !trailing.isEmpty {
                HStack(spacing: DS.Spacing.s2) {
                    ForEach(trailing.indices, id: \.self) { index in
                        ListRowTrailingView(slot: trailing[index], title: title)
                    }
                }
                .layoutPriority(1)
            }
        }
        .padding(.vertical, DS.Spacing.s2)
        .frame(minHeight: DS.Spacing.rowMin)
        .contentShape(Rectangle())
    }
}

private struct ListRowGallery: View {
    @State private var notify = true

    var body: some View {
        NomNomPreview(inNavigationStack: false) { store in
            ScrollView {
                VStack(spacing: DS.Spacing.s4) {
                    Card(layout: .list) {
                        ListRow(
                            "Spaghetti carbonara", meta: "Household \u{00B7} 30 min",
                            detail: "Extra pecorino this time.",
                            leading: .photo(store.meals.first.map { .meal($0) } ?? .none(cuisine: "italian")),
                            trailing: .score(0.82), .chevron, action: {}
                        )
                        ListRow("Tacos al pastor", meta: "Mexican \u{00B7} 4\u{00D7} cooked",
                                leading: .rank(1), trailing: .score(0.91), .chevron)
                        ListRow("Anna", meta: "Host", leading: .avatar(Avatar(name: "Anna Berg", size: .sm)),
                                trailing: .badge(.verdict(score: 0.7, size: .sm)))
                    }
                    Card(layout: .list) {
                        ListRow("Cuisine", trailing: .value("Italian"))
                        ListRow("Dish kind", trailing: .badge(Badge("Pasta", variant: .secondary, size: .sm)))
                        ListRow("Meal reminders", meta: "Every evening at 18:00", trailing: .toggle($notify))
                        ListRow("Dinner parties", meta: "2 parties", trailing: .chevron)
                        ListRow("Sam", meta: "Member", leading: .avatar(Avatar(name: "Sam", size: .sm)),
                                trailing: .button(AppButton("Follow", appearance: .soft, size: .sm) {}))
                        ListRow("New rating", meta: "2 hours ago",
                                detail: "Anna rated your carbonara Amazing and left a note about the sauce.",
                                metaTone: .accent, detailLineLimit: 2, emphasized: true)
                    }
                }
                .padding(DS.Spacing.gutter)
            }
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { ListRowGallery() }
#Preview("Dark") { ListRowGallery().preferredColorScheme(.dark) }
