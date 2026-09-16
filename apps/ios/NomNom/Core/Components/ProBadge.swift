import SwiftUI

/// Shared visual stamp for Nom Nom Pro — used on gated teasers (`ProGate`) and the paywall's
/// recommended plan so "this is Pro" reads the same everywhere in the app.
struct ProBadge: View {
    enum Size {
        case compact
        case standard

        var font: Font {
            switch self {
            case .compact: return .caption2
            case .standard: return .caption
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .compact: return 7
            case .standard: return 9
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .compact: return 3
            case .standard: return 5
            }
        }
    }

    var label: String = "PRO"
    var size: Size = .standard

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(size.font.weight(.bold))
            Text(label)
                .font(size.font.weight(.bold))
                .tracking(0.4)
        }
        .foregroundStyle(DS.Color.Pro.proAccent)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(DS.Color.Pro.proSoft)
        .clipShape(Capsule())
        .overlay {
            Capsule().strokeBorder(DS.Color.Pro.proBorder, lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 16) {
        ProBadge()
        ProBadge(size: .compact)
        ProBadge(label: "BEST VALUE")
    }
    .padding()
}
