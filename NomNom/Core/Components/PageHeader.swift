import SwiftUI

/// Reusable composable header for on-page narrative hero titles, subtitles, and metadata.
/// Standardized with `AppTypography.pageTitleFont` (32pt Newsreader Regular) and Inter metadata.
struct PageHeader: View {
    let title: String
    var subtitle: String? = nil
    var alignment: HorizontalAlignment = .center

    var body: some View {
        VStack(alignment: alignment, spacing: 6) {
            Text(title)
                .font(AppTypography.pageTitleFont)
                .multilineTextAlignment(textAlignment)
                .foregroundStyle(.primary)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.inter(.subheadline))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(textAlignment)
            }
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
        .padding(.horizontal, 16)
    }

    private var textAlignment: TextAlignment {
        switch alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        default: return .center
        }
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        default: return .center
        }
    }
}
