import SwiftUI

/// A 4-segment ascending meter representing cooking effort/duration.
/// Rising heights (7, 12, 17, 22pt) ensure legibility in 1-bit / greyscale.
struct BurnerMeter: View {
    let effort: EffortLevel?
    var showLabel: Bool = false

    private let segmentHeights: [CGFloat] = [7, 12, 17, 22]
    private let segmentWidth: CGFloat = 9

    private var filledCount: Int {
        guard let effort else { return 0 }
        switch effort {
        case .zeroTo15: return 1
        case .fifteenTo30: return 2
        case .thirtyTo60: return 3
        case .over60: return 4
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<4, id: \.self) { index in
                    let isFilled = index < filledCount
                    RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                        .fill(isFilled ? DS.Color.accent : DS.Color.lineStrong)
                        .frame(width: segmentWidth, height: segmentHeights[index])
                }
            }
            .frame(height: 22, alignment: .bottom)

            if showLabel {
                Text(effort?.label ?? "—")
                    .font(.inter(.callout))
                    .monospacedDigit()
                    .foregroundStyle(effort != nil ? DS.Color.textSecondary : DS.Color.textTertiary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(effort != nil ? "Cooking effort: \(effort!.label)" : "Cooking effort: Unspecified")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        BurnerMeter(effort: nil, showLabel: true)
        BurnerMeter(effort: .zeroTo15, showLabel: true)
        BurnerMeter(effort: .fifteenTo30, showLabel: true)
        BurnerMeter(effort: .thirtyTo60, showLabel: true)
        BurnerMeter(effort: .over60, showLabel: true)
    }
    .padding()
    .background(DS.Color.bg)
}
