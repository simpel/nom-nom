import SwiftUI

/// A key-value row pairing a leading label with trailing (or leading) wrapping chips/items.
/// Resolves SwiftUI's unconstrained width measurement bug when wrapping layouts are placed inside `HStack`.
struct LabeledWrappingRow<Content: View>: View {
    let label: String
    var alignment: HorizontalAlignment = .trailing
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6
    @ViewBuilder var content: Content

    var body: some View {
        LabeledWrapLayout(
            alignment: alignment,
            spacing: spacing,
            lineSpacing: lineSpacing
        ) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(DS.Color.textSecondary)
                .padding(.top, 2)
            content
        }
    }
}

struct LabeledWrapLayout: Layout {
    var alignment: HorizontalAlignment = .trailing
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6
    var labelGap: CGFloat = 12

    private struct Line {
        var subviews: [LayoutSubview] = []
        var sizes: [CGSize] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let label = subviews[0]
        let labelSize = label.sizeThatFits(.unspecified)

        if subviews.count == 1 {
            return labelSize
        }

        let itemSubviews = subviews.dropFirst()
        let totalWidth = proposal.width ?? .infinity
        let availableContentWidth = max(0, totalWidth - labelSize.width - labelGap)
        let lines = computeLines(subviews: Array(itemSubviews), maxWidth: availableContentWidth)

        let itemsHeight = lines.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(0, lines.count - 1))
        let maxLineWidth = lines.map(\.width).max() ?? 0
        let totalHeight = max(labelSize.height, itemsHeight)

        let resolvedWidth: CGFloat
        if let proposedWidth = proposal.width {
            resolvedWidth = proposedWidth
        } else {
            resolvedWidth = labelSize.width + labelGap + maxLineWidth
        }

        return CGSize(width: resolvedWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        let label = subviews[0]
        let labelSize = label.sizeThatFits(.unspecified)

        label.place(
            at: CGPoint(x: bounds.minX, y: bounds.minY + 2),
            anchor: .topLeading,
            proposal: ProposedViewSize(labelSize)
        )

        guard subviews.count > 1 else { return }
        let itemSubviews = Array(subviews.dropFirst())

        let contentMinX = bounds.minX + labelSize.width + labelGap
        let contentWidth = max(0, bounds.maxX - contentMinX)
        let lines = computeLines(subviews: itemSubviews, maxWidth: contentWidth)
        var y = bounds.minY

        for line in lines {
            let startX: CGFloat
            switch alignment {
            case .leading:
                startX = contentMinX
            case .trailing:
                startX = bounds.maxX - line.width
            case .center:
                startX = contentMinX + (contentWidth - line.width) / 2
            default:
                startX = bounds.maxX - line.width
            }

            var x = startX
            for (index, subview) in line.subviews.enumerated() {
                let size = line.sizes[index]
                subview.place(
                    at: CGPoint(x: x, y: y + (line.height - size.height) / 2),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += line.height + lineSpacing
        }
    }

    private func computeLines(subviews: [LayoutSubview], maxWidth: CGFloat) -> [Line] {
        var lines: [Line] = []
        var currentLine = Line()

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let potentialWidth = currentLine.subviews.isEmpty
                ? size.width
                : currentLine.width + spacing + size.width

            if potentialWidth > maxWidth && !currentLine.subviews.isEmpty {
                lines.append(currentLine)
                currentLine = Line(subviews: [subview], sizes: [size], width: size.width, height: size.height)
            } else {
                currentLine.subviews.append(subview)
                currentLine.sizes.append(size)
                currentLine.width = potentialWidth
                currentLine.height = max(currentLine.height, size.height)
            }
        }

        if !currentLine.subviews.isEmpty {
            lines.append(currentLine)
        }

        return lines
    }
}
