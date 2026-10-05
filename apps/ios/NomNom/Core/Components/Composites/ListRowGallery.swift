import SwiftUI

/// ListRow's shapes, for previews.
private struct ListRowGallery: View {
    @State private var digest = true

    var body: some View {
        NomNomPreview(inNavigationStack: false) { store in
            ScrollView {
                VStack(spacing: DS.Spacing.block) {
                    Card(layout: .list) {
                        ListRow("Spaghetti carbonara", meta: "Household \u{00B7} 30 min",
                                leading: .photo(store.meals.first.map { .meal($0) } ?? .none(cuisine: "italian")),
                                trailing: .score(0.82), action: {})
                        ListRow("Tacos al pastor", meta: "Mexican \u{00B7} 4\u{00D7} cooked",
                                leading: .rank(1), trailing: .score(0.91), action: {})
                        ListRow("Anna", meta: "Host", leading: .avatar(Avatar(name: "Anna Berg", size: .sm)),
                                trailing: .badge(.verdict(score: 0.7, size: .sm)))
                        ListRow("New rating", meta: "2 hours ago", unread: true, action: {})
                    }
                    Card(layout: .list) {
                        ListRow("Member since", value: "Mar 2026")
                        ListRow("Weekly digest", meta: "Every Sunday", trailing: .toggle($digest))
                        ListRow("Dinner parties", meta: "2 parties", action: {})
                        ListRow("Leave party", tone: .destructive, action: {})
                    }
                    DSSection("Invited") {
                        Card(layout: .list) {
                            ListRow("anna@example.com", meta: "Invited 2 days ago",
                                    leading: .avatar(Avatar(name: "anna@example.com", size: .sm)),
                                    trailing: .button(AppButton("Resend", variant: .secondary, appearance: .ghost, size: .sm) {}),
                                    trailingAction: ListRowIconAction(icon: "xmark", accessibilityLabel: "Revoke invite") {})
                        }
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
