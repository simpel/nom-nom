import SwiftUI

/// Editorial hero cover banner for category drill-down views.
struct CategoryHeroCoverCard: View {
    let category: CategoryItem
    let count: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background cover photo
            if let photoPath = category.photoPath, !photoPath.isEmpty {
                RemoteMealPhoto(path: photoPath, cornerRadius: 0, bucket: SupabaseConfig.recipeBucket)
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .clipped()
            } else if let assetImage = category.assetImageName {
                Image(assetImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .clipped()
            } else {
                Rectangle()
                    .fill(DS.Color.sunken)
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
            }

            // Scrim
            LinearGradient(
                colors: [
                    Color.black.opacity(0.05),
                    Color.black.opacity(0.35),
                    Color.black.opacity(0.80)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(category.displayName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    Text("\(count) recipe\(count == 1 ? "" : "s")")
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(DS.Color.line.opacity(0.25), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
    }
}

#Preview {
    NomNomPreview {
        CategoryHeroCoverCard(category: CategoryItem(cuisine: .mexican), count: 5)
            .padding()
    }
}
