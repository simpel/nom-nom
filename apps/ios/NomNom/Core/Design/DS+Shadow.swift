import SwiftUI

extension DS {
    /// Tailwind shadow scale (`shadow-*`), drawn from the layer lists in
    /// `DSTokens.Shadow`. Cards carry none; only things that float do. Names
    /// follow the tokens: `shadow-2xs` → `xs2`, `shadow-2xl` → `xl2`.
    enum Shadow: CaseIterable {
        case xs2, xs, sm, md, lg, xl, xl2

        var token: DSTokens.ShadowToken {
            switch self {
            case .xs2: return DSTokens.Shadow.xs2
            case .xs: return DSTokens.Shadow.xs
            case .sm: return DSTokens.Shadow.sm
            case .md: return DSTokens.Shadow.md
            case .lg: return DSTokens.Shadow.lg
            case .xl: return DSTokens.Shadow.xl
            case .xl2: return DSTokens.Shadow.xl2
            }
        }

        func layers(_ scheme: ColorScheme) -> [DSTokens.ShadowLayer] {
            scheme == .dark ? token.dark : token.light
        }
    }
}

/// Renders a CSS box-shadow layer list on a shape:
/// - an outer layer with blur or offset → `.shadow` (SwiftUI's radius is CSS blur ÷ 2;
///   SwiftUI has no spread, so a blurred layer's spread is dropped),
/// - an outer layer with only spread → a ring: the shape grown by `spread`, behind,
/// - an inset layer without blur → the band the offset uncovers inside the shape.
private struct DSShadowModifier<S: InsettableShape>: ViewModifier {
    let level: DS.Shadow
    let shape: S
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        level.layers(colorScheme).reduce(AnyView(content)) { view, layer in
            AnyView(apply(layer, to: view))
        }
    }

    @ViewBuilder
    private func apply(_ layer: DSTokens.ShadowLayer, to view: AnyView) -> some View {
        if layer.inset {
            view.overlay {
                shape.fill(layer.color)
                    .mask {
                        ZStack {
                            Rectangle()
                            shape.offset(x: layer.x, y: layer.y).blendMode(.destinationOut)
                        }
                        .compositingGroup()
                    }
                    .clipShape(shape)
                    .allowsHitTesting(false)
            }
        } else if layer.blur == 0, layer.x == 0, layer.y == 0 {
            view.background {
                shape.inset(by: -layer.spread).fill(layer.color)
            }
        } else {
            view.shadow(color: layer.color, radius: layer.blur / 2, x: layer.x, y: layer.y)
        }
    }
}

extension View {
    /// Applies a design-system shadow. Use only on things that float.
    func dsShadow<S: InsettableShape>(_ level: DS.Shadow, in shape: S) -> some View {
        modifier(DSShadowModifier(level: level, shape: shape))
    }

    /// Applies a design-system shadow on a continuous rounded rectangle
    /// (`DS.Radius.full` gives a capsule).
    @ViewBuilder
    func dsShadow(_ level: DS.Shadow, cornerRadius: CGFloat = DS.Radius.full) -> some View {
        if cornerRadius >= DS.Radius.full {
            dsShadow(level, in: Capsule())
        } else {
            dsShadow(level, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    /// The `line` hairline at `opacity-30` that rings photos, avatars and fields
    /// (PhotoCard / Avatar READMEs: "`line` ring at 30%"), drawn at `border-hairline`.
    func dsHairline(radius: CGFloat = DS.Radius.xl3) -> some View {
        overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(DS.Color.line.opacity(DS.Opacity.hairline), lineWidth: DS.BorderWidth.hairline)
        }
    }
}
