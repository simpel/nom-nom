import SwiftUI

/// ProgressBar thicknesses.
enum ProgressBarSize: Equatable, CaseIterable {
    case xs, sm, md, lg, xl

    var height: CGFloat {
        switch self {
        case .xs: return DS.Spacing.s1
        case .sm: return DS.Spacing.s1_5
        case .md: return DS.Spacing.s2
        case .lg: return DS.Spacing.s2_5
        case .xl: return DS.Spacing.s3
        }
    }
}

/// A read-only bar showing `value` out of `max` as a `primary` fill over the
/// `track`. Not a slider: to choose a value use TasteScoreSelector.
struct ProgressBar: View {
    let value: Double?
    var max: Double
    var size: ProgressBarSize
    /// On a featured card the track turns `primary` at 18%.
    var featured: Bool
    /// Accessible name; defaults to "64 out of 100".
    var label: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        value: Double?,
        max: Double = 100,
        size: ProgressBarSize = .md,
        featured: Bool = false,
        label: String? = nil
    ) {
        self.value = value
        self.max = max
        self.size = size
        self.featured = featured
        self.label = label
    }

    private var fraction: Double {
        guard let value, max > 0 else { return 0 }
        return Swift.min(Swift.max(value / max, 0), 1)
    }

    private var valueText: String {
        guard let value else { return "Not rated" }
        return "\(Int(value.rounded())) out of \(Int(max.rounded()))"
    }

    private var trackColor: Color {
        featured ? DS.Color.primary.opacity(DS.Opacity.featuredTrack) : DS.Color.track
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(trackColor)
                Capsule()
                    .fill(DS.Color.primary)
                    .frame(width: proxy.size.width * fraction)
            }
        }
        .frame(height: size.height)
        .frame(maxWidth: .infinity)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: fraction)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? valueText)
        .accessibilityValue(label == nil ? "" : valueText)
    }
}

private struct ProgressBarGallery: View {
    var body: some View {
        VStack(spacing: DS.Spacing.s4) {
            ForEach(ProgressBarSize.allCases, id: \.self) { ProgressBar(value: 64, size: $0) }
            ProgressBar(value: 5, max: 6, size: .xs, label: "5 of 6 rated")
            ProgressBar(value: nil)
            ProgressBar(value: 88, size: .lg, featured: true)
                .padding(DS.Spacing.s5)
                .background(DS.Color.primary.opacity(DS.Opacity.tint), in: RoundedRectangle(cornerRadius: DS.Radius.xl3))
        }
        .padding(DS.Spacing.s4)
        .background(DS.Color.panel)
    }
}

#Preview("Light") { ProgressBarGallery() }
#Preview("Dark") { ProgressBarGallery().preferredColorScheme(.dark) }
