import SwiftUI

/// PhotoStrip's Add photo tile (components/PhotoStrip/README.md): the strip's last tile,
/// exactly the size and shape of a photo tile in the strip's `format`. Transparent, a
/// 2px dashed `line-control` border at `radius-3xl`, a camera glyph in `primary-text`,
/// the title `sans-sm` semibold over "Camera or library" `sans-sm` tertiary. The whole
/// tile is the button. With no photos it is the only tile, labelled `emptyTitle`.
/// Where the Add photo sheet also offers AI, a `pro soft sm` "AI" Badge leads the
/// sub-line.
struct PhotoStripAddTile: View {
    var title: String = "Add photo"
    var offersAI = false
    var format: PhotoCardFormat = .portrait
    let action: () -> Void

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: PhotoCardSize.lg.radius, style: .continuous)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: DS.Spacing.s2) {
                Image(systemName: "camera")
                    .textStyle(.sansXl, tone: .accent)
                    .accessibilityHidden(true)
                VStack(spacing: 0) {
                    Text(title).textStyle(.sansSm, weight: .semibold, align: .center)
                    HStack(spacing: DS.Spacing.s1_5) {
                        if offersAI {
                            Badge("AI", icon: "sparkles", variant: .pro, size: .sm)
                        }
                        Text("Camera or library").textStyle(.sansSm, tone: .tertiary, align: .center)
                    }
                }
            }
            .padding(DS.Spacing.s4)
            .frame(
                width: format.width(longEdge: PhotoCardSize.lg.longEdge),
                height: format.height(longEdge: PhotoCardSize.lg.longEdge)
            )
            .overlay {
                // The dash length is unspecified.
                shape.strokeBorder(
                    DS.Color.lineControl,
                    style: StrokeStyle(lineWidth: DS.BorderWidth.thick, dash: [DS.Dash.length, DS.Dash.length])
                )
            }
            .contentShape(shape)
        }
        .buttonStyle(AppPressableButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityHint(offersAI ? "Generate with AI, camera or library" : "Camera or library")
        .accessibilityAddTraits(.isButton)
    }
}
