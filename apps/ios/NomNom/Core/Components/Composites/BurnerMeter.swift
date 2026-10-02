import SwiftUI

/// A 4-segment ascending meter for cooking effort. README "Colour": "effort is a
/// four-bar monochrome meter in `primary` / `line-strong`". Bars are `spacing-2` wide,
/// `spacing-1` apart, rising `spacing-2` → `spacing-5` so the order reads without colour,
/// with `radius-sm` ends. The optional label is `sans-sm` tabular, `text-secondary`
/// (`text-tertiary` when unset), `spacing-1.5` after the bars.
struct BurnerMeter: View {
    let effort: EffortLevel?
    var showLabel: Bool = false

    private static let segmentHeights: [CGFloat] = [DS.Spacing.s2, DS.Spacing.s3, DS.Spacing.s4, DS.Spacing.s5]

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
        HStack(spacing: DS.Spacing.s1_5) {
            HStack(alignment: .bottom, spacing: DS.Spacing.s1) {
                ForEach(Self.segmentHeights.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                        .fill(index < filledCount ? DS.Color.primary : DS.Color.lineStrong)
                        .frame(width: DS.Spacing.s2, height: Self.segmentHeights[index])
                }
            }
            .frame(height: DS.Spacing.s5, alignment: .bottom)

            if showLabel {
                Text(effort?.label ?? "—")
                    .textStyle(.sansSm, tone: effort != nil ? .secondary : .tertiary, numeric: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cooking effort: \(effort?.label ?? "Unspecified")")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: DS.Spacing.s4) {
        BurnerMeter(effort: nil, showLabel: true)
        BurnerMeter(effort: .zeroTo15, showLabel: true)
        BurnerMeter(effort: .fifteenTo30, showLabel: true)
        BurnerMeter(effort: .thirtyTo60, showLabel: true)
        BurnerMeter(effort: .over60, showLabel: true)
    }
    .padding(DS.Spacing.gutter)
    .background(DS.Color.bg)
}
