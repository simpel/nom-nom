import SwiftUI

/// Shared subtle capsule label used for auxiliary action buttons across heroes
/// such as "Change recipe", "Add more", "Camera", and "Photo library".
struct SubtleCapsuleLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
            Text(title)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(DS.Color.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(DS.Color.panel)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .strokeBorder(DS.Color.line.opacity(0.6), lineWidth: 0.5)
        }
    }
}
