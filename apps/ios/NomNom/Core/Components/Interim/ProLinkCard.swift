// DS-GAP: pending design system
import SwiftUI

/// A pressable Nom Nom Pro card that leads to a Pro screen (Party detail "See insights"
/// on the "Nom Nom iOS" canvas). The Pro README names link cards as entry points that
/// carry the ProMark but defines no component for them, so this wears ProCard's ground
/// (`pro-soft`, `radius-3xl`, `shadow-lg`, `spacing-5` padding) holding the ProMark, a `serif-sm` title and a
/// `sans-sm` secondary subtitle, with a `pro-text` chevron. Wrap it in a NavigationLink
/// or Button with `AppPressableButtonStyle`.
struct ProLinkCard: View {
    let title: String
    var subtitle: String?

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.xl3, style: .continuous)
    }

    var body: some View {
        HStack(spacing: DS.Spacing.s4) {
            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                ProMark()
                Text(title).textStyle(.serifSm)
                if let subtitle {
                    Text(subtitle).textStyle(.sansSm, tone: .secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .textStyle(.sansLg, weight: .semibold)
                .foregroundStyle(DS.Color.proText)
                .accessibilityHidden(true)
        }
        .padding(DS.Spacing.s5)
        .background(shape.fill(DS.Color.proSoft))
        .dsShadow(.lg, in: shape)
        .contentShape(shape)
        .accessibilityElement(children: .combine)
    }
}
