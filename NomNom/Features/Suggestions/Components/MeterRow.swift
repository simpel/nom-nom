import SwiftUI

/// Horizontal 0...1 score meter bar used for suggestion breakdown.
struct MeterRow: View {
    let title: String
    let value: Double?
    let caption: String?
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(value == nil ? "–" : "\(Int(((value ?? 0) * 100).rounded()))%")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(DS.Color.textSecondary)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.Color.sunken)
                    Capsule()
                        .fill(tint.gradient)
                        .frame(width: max(0, min(1, value ?? 0)) * geometry.size.width)
                }
            }
            .frame(height: 7)
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
