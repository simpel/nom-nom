import SwiftUI

/// Single photo card in the meal photo hero deck.
struct MealPhotoCardView: View {
    let item: FoodStore.PhotosDraft.Item
    let visualSlot: Int
    let isDragging: Bool
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                switch item {
                case .existing(let path):
                    RemoteMealPhoto(path: path, cornerRadius: AppRadius.photo, bucket: SupabaseConfig.photoBucket)
                case .added(_, let data):
                    MealPhoto(data: data, cornerRadius: AppRadius.photo)
                }
            }
            .photoBottomScrim()
            .frame(width: 144, height: 192)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                    .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(isDragging ? 0.32 : 0.16),
                    radius: isDragging ? 18 : 14,
                    x: 0,
                    y: isDragging ? 10 : 7)
            .contentShape(Rectangle())

            if !isDragging {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.65), in: Circle())
                        .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .padding(8)
            }

            if visualSlot == 0 {
                VStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                        Text("Cover")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.65), in: Capsule())
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
                    .padding(8)
                }
                .frame(width: 144, height: 192)
                .allowsHitTesting(false)
            }
        }
    }
}
