import SwiftUI

/// Visual card for a cuisine/category within the search exploration grid.
struct CategoryGridCard: View {
    let name: String
    let displayName: String
    let assetImageName: String?
    let photoPath: String?
    let count: Int
    var isSelected: Bool = false

    init(category: CategoryItem, count: Int, isSelected: Bool = false) {
        self.name = category.name
        self.displayName = category.displayName
        self.assetImageName = category.assetImageName
        self.photoPath = category.photoPath
        self.count = count
        self.isSelected = isSelected
    }

    init(cuisine: Cuisine, count: Int, isSelected: Bool = false, photoPath: String? = nil) {
        self.name = cuisine.rawValue
        self.displayName = cuisine.displayName
        self.assetImageName = cuisine.assetImageName
        self.photoPath = photoPath
        self.count = count
        self.isSelected = isSelected
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image: remote generated photo > preset asset > neutral card fallback
            if let photoPath, !photoPath.isEmpty {
                RemoteMealPhoto(path: photoPath, cornerRadius: 0, bucket: SupabaseConfig.categoryBucket)
                    .frame(maxWidth: .infinity)
                    .frame(height: 110)
                    .clipped()
            } else if let assetImageName {
                Image(assetImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 110)
                    .clipped()
            } else {
                Rectangle()
                    .fill(DS.Color.sunken)
                    .frame(maxWidth: .infinity)
                    .frame(height: 110)
            }

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
                Text(displayName)
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
        .accessibilityLabel("\(displayName), \(count) recipes\(isSelected ? ", selected" : "")")
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
