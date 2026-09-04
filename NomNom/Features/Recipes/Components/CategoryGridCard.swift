import SwiftUI

/// Visual card for a cuisine/category within the search exploration grid.
struct CategoryGridCard: View {
    let cuisine: Cuisine
    let count: Int
    var isSelected: Bool = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image with fallback
            Image(cuisine.assetImageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .clipped()

            // Gradient scrim for contrast
            LinearGradient(
                colors: [
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.35),
                    Color.black.opacity(0.75)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Selection tint overlay
            if isSelected {
                DS.Color.accent.opacity(0.18)
            }

            // Text overlay
            VStack(alignment: .leading, spacing: 2) {
                Text(cuisine.displayName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("\(count) recipe\(count == 1 ? "" : "s")")
                    .font(.caption2.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)

            // Top-trailing selection checkmark
            if isSelected {
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(DS.Color.accent)
                                .frame(width: 24, height: 24)
                            Image(systemName: "checkmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        .padding(8)
                    }
                    Spacer()
                }
            }
        }
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(
                    isSelected ? DS.Color.accent : DS.Color.line.opacity(0.3),
                    lineWidth: isSelected ? 2.5 : 0.5
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(cuisine.displayName), \(count) recipes\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    NomNomPreview {
        CategoryGridCard(cuisine: .italian, count: 8)
            .frame(width: 170)
            .padding()
    }
}
