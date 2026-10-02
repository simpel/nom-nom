import SwiftUI

/// The one way to say "this is Pro" (`design-system/components/Pro/README.md`): sparkles
/// and "Pro" in `pro-text`, `sans-xs` semibold, uppercase, `tracking-widest`. It heads
/// every ProCard, sits above a ProView's title and marks entry points (a ProLinkCard).
struct ProMark: View {
    var label = "Pro"

    var body: some View {
        HStack(spacing: DS.Spacing.s1_5) {
            Image(systemName: "sparkles").accessibilityHidden(true)
            Text(label)
                .textCase(.uppercase)
                .tracking(DS.TextStyle.sansXs.trackingWidest)
        }
        .textStyle(.sansXs, weight: .semibold)
        .foregroundStyle(DS.Color.proText)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Nom Nom Pro")
    }
}

/// No blur token exists; Pro previews blur by `shadow-md`'s blur (6pt, the README's
/// ProCard value; the ProGate's 8px has no token either). DS-GAPS.md, section C.
enum ProBlur {
    static var radius: CGFloat { DS.Shadow.md.token.light[0].blur }
}
