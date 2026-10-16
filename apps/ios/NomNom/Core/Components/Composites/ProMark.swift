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

