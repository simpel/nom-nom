import SwiftUI

/// Horizontal photo filmstrip tray showing captured / selected recipe photos with page badges and remove buttons.
struct RecipeScannerStagingTray: View {
    let photos: [Data]
    let maxPhotos: Int
    var onRemove: (Int) -> Void

    var body: some View {
        SectionCard("Captured Pages (\(photos.count)/\(maxPhotos))") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { index, data in
                        ZStack(alignment: .topTrailing) {
                            MealPhoto(data: data, cornerRadius: AppRadius.photo)
                                .frame(width: 80, height: 104)

                            // Page number badge
                            VStack {
                                Spacer()
                                HStack {
                                    Text("\(index + 1)")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Capsule())
                                    Spacer()
                                }
                                .padding(4)
                            }

                            // Remove button
                            Button {
                                onRemove(index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white, Color.black.opacity(0.6))
                                    .padding(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
