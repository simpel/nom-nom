import SwiftUI

/// A grouped list whose rows can each be swiped to reveal an action: an optional
/// `DSSection` label (`title`, `caption` as its trailing text) above a `Card(layout: .list)`
/// with one `SwipeActionRow` per item. Card draws the rows' padding and the hairline
/// between them, so `dividerPadding` is no longer read (kept for source compatibility).
struct SwipeableListCard<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    var title: String? = nil
    var caption: String? = nil
    let data: Data
    var dividerPadding: CGFloat = 0

    // Action definitions (closures so each item can conditionally enable/disable actions)
    var leadingIcon: ((Data.Element) -> String?)? = nil
    var leadingColor: ((Data.Element) -> Color?)? = nil
    var onLeadingAction: ((Data.Element) -> Void)? = nil

    var trailingIcon: ((Data.Element) -> String?)? = nil
    var trailingColor: ((Data.Element) -> Color?)? = nil
    var onTrailingAction: ((Data.Element) -> Void)? = nil

    @ViewBuilder let rowContent: (Data.Element) -> Content

    @State private var openRowID: Data.Element.ID? = nil

    var body: some View {
        Group {
            if let title {
                DSSection(title, trailing: caption) { list }
            } else {
                list
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: DS.Spacing.s1)
                .onChanged { _ in
                    // If user starts scrolling the list vertically, close any open swipe actions
                    if openRowID != nil {
                        openRowID = nil
                    }
                }
        )
    }

    private var list: some View {
        Card(layout: .list) {
            ForEach(data) { item in
                // An action is enabled for an item when its handler exists and its icon
                // closure returns non-nil for that item.
                let lIcon = leadingIcon?(item)
                let tIcon = trailingIcon?(item)
                let hasLeading = onLeadingAction != nil && lIcon != nil
                let hasTrailing = onTrailingAction != nil && tIcon != nil

                SwipeActionRow(
                    id: item.id,
                    openRowID: $openRowID,
                    leadingIcon: lIcon,
                    leadingColor: leadingColor?(item),
                    onLeadingAction: hasLeading ? { onLeadingAction?(item) } : nil,
                    trailingIcon: tIcon,
                    trailingColor: trailingColor?(item),
                    onTrailingAction: hasTrailing ? { onTrailingAction?(item) } : nil
                ) {
                    rowContent(item)
                }
            }
        }
    }
}
