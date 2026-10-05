import SwiftUI

/// What a Skeleton stands in for (`design-system/components/Skeleton/README.md`).
enum SkeletonLayout: Equatable {
    /// A `Card(layout: .list)` of ListRow-shaped rows.
    case list
    /// A Card of copy: a heading over lines.
    case card
    /// Lines of copy on the ground they sit on.
    case text
    /// One ListRow-shaped line inside a list that is otherwise there.
    case row
}

/// A row's leading bone, matching the ListRow it stands in for.
enum SkeletonLeading: Equatable { case avatar, photo }

/// The shape of content that is still on its way: `sunken` bones in the layout the
/// content will take, crossed by a `panel` sweep every `duration-shimmer`, so nothing
/// moves when it lands. A `caption` under the bones says what is happening when the work
/// takes seconds ("Working out what to change"). Reduce Motion stops the sweep and keeps
/// the bones. The whole region is one accessibility element named by the caption.
///
/// ```swift
/// Skeleton(rows: 3, trailing: true, caption: "Working out what to change")
/// Skeleton(layout: .card, lines: 2)
/// ```
struct Skeleton: View {
    var layout: SkeletonLayout = .list
    var rows: Int = 3
    var lines: Int = 3
    var leading: SkeletonLeading?
    var trailing: Bool = false
    var meta: Bool = true
    var caption: String?
    var label: String = "Loading"

    var body: some View {
        VStack(spacing: DS.Spacing.s3) {
            bones
            if let caption {
                Text(caption)
                    .textStyle(.sansSm, tone: .tertiary, align: .center)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption ?? label)
        .accessibilityAddTraits(.updatesFrequently)
    }

    @ViewBuilder private var bones: some View {
        switch layout {
        case .row:
            row(0)
        case .text:
            textLines
        case .card:
            Card {
                VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                    SkeletonBone(height: DS.Spacing.s6, widthFraction: 0.45)
                    textLines
                }
            }
        case .list:
            Card(layout: .list) {
                ForEach(0..<max(1, rows), id: \.self) { row($0) }
            }
        }
    }

    private var textLines: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            ForEach(0..<max(1, lines), id: \.self) { index in
                SkeletonBone(height: DS.Spacing.s3, widthFraction: index == lines - 1 && lines > 1 ? 0.6 : 1)
            }
        }
    }

    /// The same varied widths as the web bundle, so a list doesn't read as a barcode.
    private func row(_ index: Int) -> some View {
        HStack(spacing: DS.Spacing.s3) {
            switch leading {
            case .avatar: SkeletonBone(width: DS.Spacing.s8, height: DS.Spacing.s8)
            case .photo: SkeletonBone(width: DS.Spacing.s11, height: DS.Spacing.s11, cornerRadius: DS.Radius.xl)
            case nil: EmptyView()
            }
            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                SkeletonBone(height: DS.Spacing.s4, widthFraction: Double(55 + (index * 17) % 30) / 100)
                if meta {
                    SkeletonBone(height: DS.Spacing.s3, widthFraction: Double(70 + (index * 11) % 25) / 100)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if trailing {
                SkeletonBone(width: DS.Spacing.s10, height: DS.Spacing.s6)
            }
        }
        .padding(.vertical, DS.Spacing.s3)
        .frame(minHeight: DS.Spacing.s14)
    }
}

/// One bone: a `sunken` pill (or a tile at `cornerRadius`) with the shimmer sweep. Use it
/// on its own only to stand in for one element whose shape no `Skeleton` layout has (a
/// score numeral, a wordmark's loading line).
struct SkeletonBone: View {
    var width: CGFloat?
    var height: CGFloat
    var widthFraction: Double = 1
    var cornerRadius: CGFloat = DS.Radius.full

    var body: some View {
        GeometryReader { proxy in
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            shape
                .fill(DS.Color.sunken)
                .skeletonShimmer()
                .clipShape(shape)
                .frame(width: width ?? proxy.size.width * widthFraction)
        }
        .frame(width: width, height: height)
        .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
        .accessibilityHidden(true)
    }
}

extension View {
    /// The Skeleton sweep over any loading ground (a bone, a photo tile still downloading):
    /// `panel` at `opacity-70` crossing left to right every `duration-shimmer`. Reduce
    /// Motion leaves the ground still. Clip to the ground's shape.
    func skeletonShimmer() -> some View {
        modifier(SkeletonShimmer())
    }
}

private struct SkeletonShimmer: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sweep = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [.clear, DS.Color.panel.opacity(DS.Opacity.o70), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .offset(x: sweep ? proxy.size.width : -proxy.size.width)
                    }
                    .allowsHitTesting(false)
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(DS.Motion.shimmer) { sweep = true }
            }
    }
}

private struct SkeletonGallery: View {
    var body: some View {
        VStack(spacing: DS.Spacing.block) {
            Skeleton(rows: 3, trailing: true, caption: "Working out what to change")
            Skeleton(rows: 2, leading: .avatar, trailing: true)
            Skeleton(layout: .card, lines: 2)
        }
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { SkeletonGallery() }
#Preview("Dark") { SkeletonGallery().preferredColorScheme(.dark) }
