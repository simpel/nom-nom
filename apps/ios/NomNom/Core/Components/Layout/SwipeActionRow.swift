import SwiftUI

/// A custom wrapper that enables Apple-style swipe-to-reveal actions inside `ScrollView` / `VStack` lists,
/// bypassing SwiftUI's limitation that `swipeActions` only works natively inside `List`.
struct SwipeActionRow<ID: Hashable, Content: View>: View {
    let id: ID
    @Binding var openRowID: ID?

    var leadingIcon: String? = nil
    var leadingColor: Color? = nil
    var onLeadingAction: (() -> Void)? = nil
    
    var trailingIcon: String? = nil
    var trailingColor: Color? = nil
    var onTrailingAction: (() -> Void)? = nil

    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var isSwipedLeading = false
    @State private var isSwipedTrailing = false
    
    private let buttonWidth: CGFloat = 74
    private let fullSwipeThreshold: CGFloat = 160

    init(
        id: ID,
        openRowID: Binding<ID?>,
        leadingIcon: String? = nil,
        leadingColor: Color? = nil,
        onLeadingAction: (() -> Void)? = nil,
        trailingIcon: String? = nil,
        trailingColor: Color? = nil,
        onTrailingAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.id = id
        self._openRowID = openRowID
        self.leadingIcon = leadingIcon
        self.leadingColor = leadingColor
        self.onLeadingAction = onLeadingAction
        self.trailingIcon = trailingIcon
        self.trailingColor = trailingColor
        self.onTrailingAction = onTrailingAction
        self.content = content
    }

    var body: some View {
        ZStack {
            // Background Action Areas
            GeometryReader { geo in
                // Leading Background (Swiping Right)
                if onLeadingAction != nil, offset > 0 {
                    ZStack(alignment: .trailing) {
                        leadingColor
                        if let leadingIcon {
                            Image(systemName: leadingIcon)
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.white)
                                .frame(width: buttonWidth)
                        }
                    }
                    .frame(width: offset, height: geo.size.height)
                    .clipped()
                    .onTapGesture {
                        closeAndTrigger(action: onLeadingAction)
                    }
                }
                
                // Trailing Background (Swiping Left)
                if onTrailingAction != nil, offset < 0 {
                    ZStack(alignment: .leading) {
                        trailingColor
                        if let trailingIcon {
                            Image(systemName: trailingIcon)
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.white)
                                .frame(width: buttonWidth)
                        }
                    }
                    .frame(width: -offset, height: geo.size.height)
                    .offset(x: geo.size.width + offset)
                    .clipped()
                    .onTapGesture {
                        closeAndTrigger(action: onTrailingAction)
                    }
                }
            }
            .onTapGesture {
                if isSwipedLeading || isSwipedTrailing {
                    closeAndTrigger(action: nil)
                }
            }

            // Foreground Content
            content()
                .background(DS.Color.panel)
                .overlay {
                    // Swallow taps if THIS row is swiped open
                    if isSwipedLeading || isSwipedTrailing {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                closeAndTrigger(action: nil)
                            }
                    }
                    // Swallow taps if ANOTHER row is swiped open
                    else if openRowID != nil && openRowID != id {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                openRowID = nil
                            }
                    }
                }
                .offset(x: offset)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 15)
                        .onChanged { value in
                            if openRowID != id {
                                openRowID = id
                            }
                            
                            let canSwipeRight = onLeadingAction != nil
                            let canSwipeLeft = onTrailingAction != nil
                            
                            var newOffset = value.translation.width
                            if isSwipedLeading {
                                newOffset += buttonWidth
                            } else if isSwipedTrailing {
                                newOffset -= buttonWidth
                            }
                            
                            // Constrain to available actions
                            if newOffset > 0 && !canSwipeRight {
                                newOffset = 0
                            } else if newOffset < 0 && !canSwipeLeft {
                                newOffset = 0
                            }
                            
                            offset = newOffset
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if offset >= fullSwipeThreshold {
                                    // Full leading swipe
                                    closeAndTrigger(action: onLeadingAction)
                                } else if offset <= -fullSwipeThreshold {
                                    // Full trailing swipe
                                    closeAndTrigger(action: onTrailingAction)
                                } else if offset >= buttonWidth * 0.5 {
                                    // Snap open leading
                                    offset = buttonWidth
                                    isSwipedLeading = true
                                    isSwipedTrailing = false
                                } else if offset <= -buttonWidth * 0.5 {
                                    // Snap open trailing
                                    offset = -buttonWidth
                                    isSwipedTrailing = true
                                    isSwipedLeading = false
                                } else {
                                    // Snap closed
                                    offset = 0
                                    isSwipedLeading = false
                                    isSwipedTrailing = false
                                    if openRowID == id {
                                        openRowID = nil
                                    }
                                }
                            }
                        }
                )
        }
        .onChange(of: openRowID) { _, newValue in
            if newValue != id && (isSwipedLeading || isSwipedTrailing || offset != 0) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offset = 0
                    isSwipedLeading = false
                    isSwipedTrailing = false
                }
            }
        }
    }
    
    private func closeAndTrigger(action: (() -> Void)?) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = 0
            isSwipedLeading = false
            isSwipedTrailing = false
            if openRowID == id {
                openRowID = nil
            }
        }
        if let action {
            // Slight delay so the UI snaps back before the destructive action potentially removes the row
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                action()
            }
        }
    }
}
