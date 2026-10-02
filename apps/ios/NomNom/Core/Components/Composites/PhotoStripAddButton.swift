import SwiftUI

/// PhotoStrip's floating "Add photo" button: AppButton `secondary elevated sm` with a
/// camera icon that collapses to an icon-only circle once the strip scrolls. The label
/// fades over `duration-state` (150ms) while the width animates over `duration-layout`
/// (250ms) ease-out; Reduce Motion crossfades the two states instead. The accessible
/// name stays "Add photo" in both.
///
/// README: "collapses to a `spacing-9` icon-only circle". AppButton's 44pt floor wins,
/// so the collapsed button is AppButton's one 44pt icon-only circle (DS-GAPS.md).
struct PhotoStripAddButton: View {
    var isCollapsed: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            label
                .id(reduceMotion ? isCollapsed : false)
                .transition(.opacity.animation(DS.Motion.state))
        }
        .buttonStyle(AppPressableButtonStyle())
        .animation(reduceMotion ? DS.Motion.state : DS.Motion.layout, value: isCollapsed)
    }

    @ViewBuilder
    private var label: some View {
        if isCollapsed {
            AppButtonLabel(icon: "camera", accessibilityLabel: "Add photo", variant: .secondary, appearance: .elevated)
        } else {
            AppButtonLabel("Add photo", icon: "camera", variant: .secondary, appearance: .elevated, size: .sm)
        }
    }
}

/// PhotoStrip's empty state when the viewer can add photos: a quiet `s20` tile (`s24`
/// when the strip is landscape) with a dashed border, a camera glyph in `primary-text`,
/// "Add a photo" `sans-sm` semibold over "Camera or library" `sans-sm` tertiary. The
/// whole tile is the button.
struct PhotoStripEmptyAddTile: View {
    var title: String = "Add a photo"
    var isLandscape: Bool = false
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
                    Text(title).textStyle(.sansSm, weight: .semibold)
                    Text("Camera or library").textStyle(.sansSm, tone: .tertiary)
                }
            }
            .padding(.horizontal, DS.Spacing.s5)
            .frame(maxWidth: .infinity, minHeight: isLandscape ? DS.Spacing.s24 : DS.Spacing.s20, alignment: .leading)
            .overlay {
                // README: "1.5px dashed `line-placeholder`". No `line-placeholder` token and no
                // 1.5px width: `line-control` (root README, "the dashed placeholder tile")
                // at `border-thick` (bundle.css). The dash length is unspecified (DS-GAPS.md).
                shape.strokeBorder(
                    DS.Color.lineControl,
                    style: StrokeStyle(lineWidth: DS.BorderWidth.thick, dash: [DS.Spacing.s1, DS.Spacing.s1])
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
