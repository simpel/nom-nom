import SwiftUI

/// A unified component that combines a `SectionCard`, an `AppList`, and `SwipeActionRow`s for each item.
/// This allows you to easily render grouped lists where every item can be swiped to reveal actions.
struct SwipeableListCard<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    var title: String? = nil
    var caption: String? = nil
    let data: Data
    var dividerPadding: CGFloat = 16
    
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
        SectionCard(title: title, caption: caption, innerPadding: 0) {
            AppList(data: data, dividerPadding: dividerPadding) { item in
                
                // We resolve the closures here so the row knows if it can swipe
                // We assume that if `onLeadingAction` was provided AND `leadingIcon` returns non-nil for this item,
                // then the action is enabled for this specific item.
                let lIcon = leadingIcon?(item)
                let tIcon = trailingIcon?(item)
                let lColor = leadingColor?(item)
                let tColor = trailingColor?(item)
                
                let hasLeading = onLeadingAction != nil && lIcon != nil
                let hasTrailing = onTrailingAction != nil && tIcon != nil
                
                SwipeActionRow(
                    id: item.id,
                    openRowID: $openRowID,
                    leadingIcon: lIcon,
                    leadingColor: lColor,
                    onLeadingAction: hasLeading ? { onLeadingAction?(item) } : nil,
                    trailingIcon: tIcon,
                    trailingColor: tColor,
                    onTrailingAction: hasTrailing ? { onTrailingAction?(item) } : nil
                ) {
                    rowContent(item)
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 5)
                .onChanged { _ in
                    // If user starts scrolling the list vertically, close any open swipe actions
                    if openRowID != nil {
                        openRowID = nil
                    }
                }
        )
    }
}
