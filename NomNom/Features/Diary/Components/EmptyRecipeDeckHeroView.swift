import SwiftUI

/// Three-card tilted hero card deck displayed when no recipe has been selected yet.
/// Tapping the deck opens the recipe picker.
struct EmptyRecipeDeckHeroView: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                    .fill(Color.orange.opacity(0.04))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                            .strokeBorder(Color.orange.opacity(0.20), lineWidth: 1.5)
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
                                    .fill(Color.orange.opacity(0.12))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(Color.orange)
                            }

                            Text("Pick a Recipe")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(DS.Color.textPrimary)

                            Text("Tap to choose")
                                .font(.caption2)
                                .foregroundStyle(DS.Color.textSecondary)

                            VStack(spacing: 3) {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(DS.Color.line.opacity(0.7))
                                    .frame(width: 44, height: 2)
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(DS.Color.line.opacity(0.45))
                                    .frame(width: 28, height: 2)
                            }
                            .padding(.top, 2)
                        }
                        .padding(12)
                    }
                    .frame(width: 144, height: 192)
                    .shadow(color: Color.black.opacity(0.16), radius: 14, x: 0, y: 7)
            }
            .frame(height: 220)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
