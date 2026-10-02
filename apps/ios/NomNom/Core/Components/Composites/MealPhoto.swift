import SwiftUI
import UIKit

/// A photo of a meal from in-memory data, or the no-photo tile. README "Imagery": "No
/// photo: `sunken` tile, `text-tertiary` fork-and-knife glyph, caption 'No photo yet'",
/// drawn as PhotoCard's tile (glyph `sans-xl`, caption `sans-sm`, `spacing-1` apart).
/// Corners default to `radius-2xl` ("photos inside a list").
struct MealPhoto: View {
    let data: Data?
    var cornerRadius: CGFloat = DS.Radius.xl2

    var body: some View {
        ZStack {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                DS.Color.sunken
                VStack(spacing: DS.Spacing.s1) {
                    Image(systemName: "fork.knife").textStyle(.sansXl, tone: .tertiary)
                    Text("No photo yet").textStyle(.sansSm, tone: .tertiary, align: .center)
                }
                .padding(DS.Spacing.s2)
                .accessibilityElement(children: .combine)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
