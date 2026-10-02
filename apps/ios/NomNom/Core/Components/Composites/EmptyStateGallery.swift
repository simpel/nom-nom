import SwiftUI

/// EmptyState's four layouts, for previews.
private struct EmptyStateGallery: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.block) {
                EmptyState(
                    "No meals yet",
                    message: "Log tonight\u{2019}s dinner and it will show up here.",
                    icon: "fork.knife",
                    layout: .screen,
                    action: EmptyStateAction("Log a meal") {}
                )
                EmptyState(
                    "No recipes match \u{2018}laxpudding\u{2019}",
                    message: "Try a shorter search.",
                    action: EmptyStateAction("Clear search", variant: .secondary) {}
                )
                Card {
                    EmptyState("Nobody has rated this", message: "Ratings show up once someone has eaten.", layout: .plain)
                }
                Card(layout: .list) {
                    EmptyState("No photo yet", icon: "camera", layout: .row,
                               action: EmptyStateAction("Add photo") {})
                }
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}

#Preview("Light") { EmptyStateGallery() }
#Preview("Dark") { EmptyStateGallery().preferredColorScheme(.dark) }
