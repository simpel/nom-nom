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
    /// The axis a drag committed to on its first movement. A vertical drag is left
    /// to the enclosing ScrollView for the rest of the gesture.
    @State private var dragAxis: Axis?
    
    /// The revealed action is `spacing-20` wide; a drag past two widths fires it.
    private let buttonWidth = DS.Spacing.s20
    private var fullSwipeThreshold: CGFloat { buttonWidth * 2 }
    /// The snap: `duration-layout` (README "Motion and states": the layout duration).
    private var snap: Animation { .spring(duration: DS.Motion.durationLayout) }

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
                            actionIcon(leadingIcon, on: leadingColor)
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
                            actionIcon(trailingIcon, on: trailingColor)
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
                .modifier(SwipeDragGesture(isEnabled: hasActions, onChanged: dragChanged, onEnded: dragEnded))
        }
        .onChange(of: openRowID) { _, newValue in
            if newValue != id && (isSwipedLeading || isSwipedTrailing || offset != 0) {
                withAnimation(snap) {
                    offset = 0
                    isSwipedLeading = false
                    isSwipedTrailing = false
                }
            }
        }
    }
    
    /// The action glyph in `sans-xl`, inked in the ground's `on-{role}` colour.
    private func actionIcon(_ systemName: String, on ground: Color?) -> some View {
        Image(systemName: systemName)
            .textStyle(.sansXl, tone: nil)
            .foregroundStyle(Self.ink(on: ground))
            .frame(width: buttonWidth)
    }

    private static func ink(on ground: Color?) -> Color {
        let roles: [DS.Role] = [.primary, .secondary, .destructive, .pro, .warning]
        return roles.first { $0.fill == ground }?.on ?? DS.Color.onDestructive
    }

    /// A drag moved by `translation`. With `axisKnown` (the iOS 18 pan, which only begins
    /// sideways) the axis is horizontal; otherwise the first movement decides it, and a
    /// vertical drag is left to the enclosing ScrollView.
    private func dragChanged(_ translation: CGSize, axisKnown: Bool) {
        if dragAxis == nil {
            dragAxis = axisKnown || abs(translation.width) > abs(translation.height) ? .horizontal : .vertical
        }
        guard dragAxis == .horizontal else { return }

        if openRowID != id {
            openRowID = id
        }

        var newOffset = translation.width
        if isSwipedLeading {
            newOffset += buttonWidth
        } else if isSwipedTrailing {
            newOffset -= buttonWidth
        }

        // Constrain to available actions
        if newOffset > 0 && onLeadingAction == nil {
            newOffset = 0
        } else if newOffset < 0 && onTrailingAction == nil {
            newOffset = 0
        }

        offset = newOffset
    }

    private func dragEnded() {
        defer { dragAxis = nil }
        guard dragAxis == .horizontal else { return }
        withAnimation(snap) {
            if offset >= fullSwipeThreshold {
                closeAndTrigger(action: onLeadingAction)
            } else if offset <= -fullSwipeThreshold {
                closeAndTrigger(action: onTrailingAction)
            } else if offset >= buttonWidth * 0.5 {
                offset = buttonWidth
                isSwipedLeading = true
                isSwipedTrailing = false
            } else if offset <= -buttonWidth * 0.5 {
                offset = -buttonWidth
                isSwipedTrailing = true
                isSwipedLeading = false
            } else {
                offset = 0
                isSwipedLeading = false
                isSwipedTrailing = false
                if openRowID == id {
                    openRowID = nil
                }
            }
        }
    }

    private var hasActions: Bool { onLeadingAction != nil || onTrailingAction != nil }

    private func closeAndTrigger(action: (() -> Void)?) {
        withAnimation(snap) {
            offset = 0
            isSwipedLeading = false
            isSwipedTrailing = false
            if openRowID == id {
                openRowID = nil
            }
        }
        if let action {
            // Wait out `duration-state` so the row snaps back before the action
            // potentially removes it.
            DispatchQueue.main.asyncAfter(deadline: .now() + DS.Motion.durationState) {
                action()
            }
        }
    }
}
