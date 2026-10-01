import SwiftUI

extension DS {
    /// Tailwind shadow scale (`shadow-*` in `tokens.json`). Cards carry none;
    /// only things that float do. In dark a black shadow can't show on a
    /// near-black ground, so each dark level leads with a 1px white ring and a
    /// faint top highlight.
    enum Shadow {
        case xs, sm, md, lg, xl

        struct Layer {
            let opacity: Double
            let radius: CGFloat
            let y: CGFloat
        }

        /// Light-theme layers. SwiftUI has no spread, so blur/2 approximates radius.
        var lightLayers: [Layer] {
            switch self {
            case .xs: return [Layer(opacity: 0.05, radius: 1, y: 1)]
            case .sm: return [Layer(opacity: 0.10, radius: 1.5, y: 1), Layer(opacity: 0.10, radius: 1, y: 1)]
            case .md: return [Layer(opacity: 0.10, radius: 3, y: 4), Layer(opacity: 0.10, radius: 2, y: 2)]
            case .lg: return [Layer(opacity: 0.10, radius: 7.5, y: 10), Layer(opacity: 0.10, radius: 3, y: 4)]
            case .xl: return [Layer(opacity: 0.10, radius: 12.5, y: 20), Layer(opacity: 0.10, radius: 5, y: 8)]
            }
        }

        /// Dark-theme black drop.
        var darkLayer: Layer {
            switch self {
            case .xs: return Layer(opacity: 0.6, radius: 1, y: 1)
            case .sm: return Layer(opacity: 0.6, radius: 1.5, y: 1)
            case .md: return Layer(opacity: 0.6, radius: 4, y: 4)
            case .lg: return Layer(opacity: 0.7, radius: 10, y: 10)
            case .xl: return Layer(opacity: 0.7, radius: 15, y: 20)
            }
        }

        /// Dark-theme 1px white ring opacity.
        var darkRingOpacity: Double {
            switch self {
            case .xs: return 0.10
            case .sm, .md: return 0.08
            case .lg, .xl: return 0.10
            }
        }

        /// Dark-theme top highlight opacity (`inset 0 1px 0`).
        static let darkHighlightOpacity: Double = 0.05
    }
}

private struct DSShadowModifier<S: InsettableShape>: ViewModifier {
    let level: DS.Shadow
    let shape: S
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            let drop = level.darkLayer
            content
                .overlay {
                    shape.strokeBorder(Color.white.opacity(level.darkRingOpacity), lineWidth: 1)
                }
                .overlay {
                    shape.strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(DS.Shadow.darkHighlightOpacity), .clear],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 1
                    )
                }
                .shadow(color: .black.opacity(drop.opacity), radius: drop.radius, x: 0, y: drop.y)
        } else {
            level.lightLayers.reduce(AnyView(content)) { view, layer in
                AnyView(view.shadow(color: .black.opacity(layer.opacity), radius: layer.radius, x: 0, y: layer.y))
            }
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

    /// The 0.5pt `line` hairline at `opacity-30` that outlines photos and fields.
    func dsHairline(radius: CGFloat = DS.Radius.xl3) -> some View {
        overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(DS.Color.line.opacity(DS.Opacity.hairline), lineWidth: 0.5)
        }
    }
}
