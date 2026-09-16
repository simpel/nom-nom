import SwiftUI

/// Chips and items laid out horizontally, wrapping onto new lines dynamically.
struct WrappingHStack<Content: View>: View {
    var alignment: HorizontalAlignment = .leading
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6
    @ViewBuilder var content: Content

    var body: some View {
        let layout = WrapLayout(alignment: alignment, spacing: spacing, lineSpacing: lineSpacing)
        return layout { content }
    }
}

struct WrapLayout: Layout {
    var alignment: HorizontalAlignment = .leading
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    private struct Line {
        var subviews: [LayoutSubview] = []
        var sizes: [CGSize] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let maxWidth = proposal.width ?? .infinity
        let lines = computeLines(subviews: subviews, maxWidth: maxWidth)

        let totalHeight = lines.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(0, lines.count - 1))
        let maxLineWidth = lines.map(\.width).max() ?? 0

        let resolvedWidth: CGFloat
        if let proposedWidth = proposal.width {
            resolvedWidth = proposedWidth
        } else {
            resolvedWidth = maxLineWidth
        }

        return CGSize(width: resolvedWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        let lines = computeLines(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY

        for line in lines {
            let startX: CGFloat
            switch alignment {
            case .trailing:
                startX = bounds.maxX - line.width
            case .center:
                startX = bounds.minX + (bounds.width - line.width) / 2
            default: // .leading
                startX = bounds.minX
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

    private func computeLines(subviews: Subviews, maxWidth: CGFloat) -> [Line] {
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
