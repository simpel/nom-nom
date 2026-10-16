// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// The photo editor's placeholder for an AI photo that will be made when the recipe is
/// saved: a PhotoCard-sized `pro-soft` tile with sparkles in `pro-text`, "AI photo when
/// you save" and "Tap to undo". Tapping it takes the AI photo back out.
struct PendingAIPhotoTile: View {
    var size: PhotoCardSize = .sm
    let onUndo: () -> Void

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: size.radius, style: .continuous)
    }

    var body: some View {
        Button(action: onUndo) {
            VStack(spacing: DS.Spacing.s2) {
                Image(systemName: "sparkles")
                    .textStyle(.sansXl, tone: nil)
                    .foregroundStyle(DS.Color.proText)
                    .accessibilityHidden(true)
                VStack(spacing: 0) {
                    Text("AI photo when you save").textStyle(.sansSm, weight: .semibold, align: .center)
                    Text("Tap to undo").textStyle(.sansSm, tone: .secondary, align: .center)
                }
            }
            .padding(DS.Spacing.s4)
            .frame(
                width: size.defaultFormat.width(longEdge: size.longEdge),
                height: size.defaultFormat.height(longEdge: size.longEdge)
            )
            .background(shape.fill(DS.Color.proSoft))
            .contentShape(shape)
        }
        .buttonStyle(AppPressableButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("AI photo when you save")
        .accessibilityHint("Removes the AI photo")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("Light") {
    NomNomPreview(inNavigationStack: false) { _ in
        PendingAIPhotoTile {}.padding(DS.Spacing.gutter).background(DS.Color.bg)
    }
}
