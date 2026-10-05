import SwiftUI

/// The Insights tab while a party's insights load, in the dashboard's own order: the
/// taste-match list, the health score card and the macro card. Skeleton parts only.
struct InsightsSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.block) {
                Skeleton(rows: 4, leading: .avatar, trailing: true, label: "Loading insights")
                Skeleton(layout: .card, lines: 2, label: "Loading insights")
                Skeleton(layout: .card, lines: 3, label: "Loading insights")
            }
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s4)
        }
        .scrollDisabled(true)
        .background(DS.Color.bg)
    }
}
