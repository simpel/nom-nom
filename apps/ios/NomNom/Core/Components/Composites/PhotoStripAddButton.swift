import SwiftUI

/// PhotoStrip's floating "Add photo" button: AppButton `secondary elevated sm` with a
/// camera icon that collapses to an `s9` icon-only circle once the strip scrolls.
/// Width animates 250ms ease-out; Reduce Motion crossfades the two states instead.
/// The accessible name stays "Add photo" in both.
struct PhotoStripAddButton: View {
    var isCollapsed: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            AppButtonLabel(
                isCollapsed ? nil : "Add photo",
                icon: "camera",
                variant: .secondary,
                appearance: .elevated,
                size: .sm,
                accessibilityLabel: "Add photo"
            )
            .id(reduceMotion ? isCollapsed : false)
            .transition(.opacity.animation(.easeOut(duration: 0.15)))
        }
        .buttonStyle(AppPressableButtonStyle())
        .animation(reduceMotion ? .easeOut(duration: 0.15) : .easeOut(duration: 0.25), value: isCollapsed)
    }
}

/// PhotoStrip's empty state when the viewer can add photos: a quiet `s20` tile with a
/// 1.5pt dashed `line-placeholder` border. The whole tile is the button.
struct PhotoStripEmptyAddTile: View {
    let action: () -> Void

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.xl3, style: .continuous)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.s3) {
                Image(systemName: "camera")
                    .textStyle(.sansXl, tone: .accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Add a photo").textStyle(.sansSm, weight: .semibold)
                    Text("Camera or library").textStyle(.sansSm, tone: .tertiary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: DS.Spacing.s20)
            .overlay {
                shape.strokeBorder(
                    DS.Color.lineControl,  // README: the dashed placeholder tile uses `line-control`
                    style: StrokeStyle(lineWidth: DSAppearance.outlineWidth, dash: [DS.Spacing.s1, DS.Spacing.s1])
                )
            }
            .contentShape(shape)
        }
        .buttonStyle(AppPressableButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Add photo")
        .accessibilityHint("Camera or library")
        .accessibilityAddTraits(.isButton)
    }
}
