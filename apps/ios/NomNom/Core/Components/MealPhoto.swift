import SwiftUI
import UIKit

/// A photo of a meal from in-memory data, or a friendly placeholder.
struct MealPhoto: View {
    let data: Data?
    var cornerRadius: CGFloat = AppRadius.photo

    var body: some View {
        ZStack {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(DS.Color.sunken)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(DS.Color.line, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                    VStack(spacing: 6) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(DS.Color.textTertiary)
                        Text("No photo yet")
                            .font(.inter(.caption2))
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                    .padding(8)
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
