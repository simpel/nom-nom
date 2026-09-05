import SwiftUI
import PhotosUI

/// Three-card tilted hero card deck displayed when no photos have been chosen yet.
/// Tapping the deck opens the photo picker.
struct EmptyPhotoDeckHeroView: View {
    @Binding var selectedPickerItems: [PhotosPickerItem]
    var title: String = "Add Photos"
    var subtitle: String = "Tap to choose"
    var maxSelectionCount: Int = FoodStore.PhotosDraft.maxCount
    var onDeckTap: (() -> Void)? = nil

    var body: some View {
        if let onDeckTap, CameraPicker.isAvailable {
            Button {
                onDeckTap()
            } label: {
                deckContent
            }
            .buttonStyle(.plain)
        } else {
            PhotosPicker(
                selection: $selectedPickerItems,
                maxSelectionCount: maxSelectionCount,
                matching: .images,
                photoLibrary: .shared()
            ) {
                deckContent
            }
            .buttonStyle(.plain)
        }
    }

    private var deckContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                .fill(Color.accentColor.opacity(0.04))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1.5)
                }
                .frame(width: 144, height: 192)
                .rotationEffect(.degrees(-7))
                .offset(x: -22, y: 4)

            RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                .fill(DS.Color.sunken)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                        .strokeBorder(DS.Color.line, lineWidth: 1.5)
                }
                .frame(width: 144, height: 192)
                .rotationEffect(.degrees(7))
                .offset(x: 22, y: 4)

            RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                .fill(DS.Color.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                        .strokeBorder(DS.Color.lineStrong, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                }
                .overlay {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(DS.Color.accentSoft)
                                .frame(width: 52, height: 52)
                            Image(systemName: "camera")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(DS.Color.accentText)
                        }

                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(DS.Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .multilineTextAlignment(.center)
                    .padding(12)
                }
                .frame(width: 144, height: 192)
                .shadow(color: Color.black.opacity(0.16), radius: 14, x: 0, y: 7)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }
}
