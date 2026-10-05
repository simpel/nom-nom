import SwiftUI
import RevenueCat

/// One subscription option on the paywall. A "kept as-is" block awaiting a design
/// (DS-GAPS.md "Paywall package cards"): a `panel` card at `radius-2xl`, the best-value
/// plan tinted `pro` at `opacity-10` with a `pro` "Best value" Badge on its top edge,
/// a `border-hairline` ring at rest and `border-thick` when selected.
struct PaywallPackageCard: View {
    let package: Package
    let title: String
    let subtitle: String
    var isBestValue: Bool = false
    let isSelected: Bool
    let onSelect: () -> Void

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.xl2, style: .continuous)
    }

    private var ring: Color {
        if isBestValue { return DS.Color.proText }
        return isSelected ? DS.Color.primary : DS.Color.line
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DS.Spacing.s3) {
                VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                    Text(title)
                        .textStyle(.sansLg, tone: nil, weight: .semibold)
                        .foregroundStyle(isBestValue ? DS.Color.proText : DS.Color.textPrimary)
                    Text(subtitle)
                        .textStyle(.sansMd, tone: nil)
                        .foregroundStyle(isBestValue ? DS.Color.proText : DS.Color.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(package.localizedPriceString)
                    .textStyle(.sansLg, tone: nil, weight: .semibold, numeric: true)
                    .foregroundStyle(isBestValue ? DS.Color.proText : DS.Color.textPrimary)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .textStyle(.sansLg, tone: nil)
                    .foregroundStyle(isSelected ? (isBestValue ? DS.Color.pro : DS.Color.primary) : DS.Color.lineControl)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.vertical, isBestValue ? DS.Spacing.s5 : DS.Spacing.s4)
            .background {
                shape
                    .fill(DS.Color.panel)
                    .overlay {
                        if isBestValue {
                            shape.fill(DS.Color.pro.opacity(DS.Opacity.tint))
                        }
                    }
            }
            .overlay {
                shape.strokeBorder(ring, lineWidth: isSelected ? DS.BorderWidth.thick : DS.BorderWidth.hairline)
            }
            .overlay(alignment: .topTrailing) {
                if isBestValue {
                    // Straddles the top border, inset `spacing-4` from the corner.
                    Badge("Best value", variant: .pro, appearance: .solid, size: .sm)
                        .padding(.trailing, DS.Spacing.s4)
                        .alignmentGuide(.top) { $0.height / 2 }
                }
            }
            .contentShape(shape)
        }
        .buttonStyle(AppPressableButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
