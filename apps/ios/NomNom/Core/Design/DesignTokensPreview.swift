import SwiftUI

/// Preview surface rendering every design-system token in Light and Dark.
/// Swatch tables live in `DesignTokensPreview+Data.swift`.
struct DesignTokensPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s8) {
                Text("Design system tokens")
                    .textStyle(.serifLg)

                swatchGrid("Surfaces and text", Self.surfaces)
                swatchGrid("Roles", Self.roleSwatches)
                swatchGrid("Reaction ramp", Self.reactions)
                ramp("Chart series", DS.Color.chartSeries.enumerated().map { ("\($0.offset + 1)", $0.element) })
                ramp("Stone", Self.stoneRamp)
                ramp("Pine", Self.pineRamp)
                typeScale
                radiusAndShadow
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }

    private func heading(_ title: String) -> some View {
        SectionHeader(title: title)
    }

    private func swatchGrid(_ title: String, _ swatches: [(name: String, color: Color)]) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            heading(title)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: DS.Spacing.s24), spacing: DS.Spacing.s2)], spacing: DS.Spacing.s2) {
                ForEach(swatches, id: \.name) { swatch in
                    VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                        RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                            .fill(swatch.color)
                            .frame(height: DS.Spacing.s10)
                            .dsHairline(radius: DS.Radius.xl)
                        Text(swatch.name)
                            .textStyle(.sansXs, tone: .secondary, lines: 1)
                            .truncationMode(.middle)
                    }
                }
            }
        }
    }

    private func ramp(_ title: String, _ steps: [(name: String, color: Color)]) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            heading(title)
            HStack(spacing: DS.Spacing.s0_5) {
                ForEach(steps, id: \.name) { step in
                    Rectangle().fill(step.color).frame(height: DS.Spacing.s7)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))
        }
    }

    private var typeScale: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            heading("Type")
            ForEach(DS.TextStyle.allCases, id: \.self) { style in
                Text("\(String(describing: style)) \(Int(style.size))")
                    .textStyle(style, numeric: true)
            }
            Text("Cook's note in italic").textStyle(.serifXs, tone: .secondary, italic: true)
            HStack(spacing: DS.Spacing.s4) {
                Text("primary").textStyle(.sansSm, tone: .primary)
                Text("secondary").textStyle(.sansSm, tone: .secondary)
                Text("tertiary").textStyle(.sansSm, tone: .tertiary)
                Text("accent").textStyle(.sansSm, tone: .accent)
            }
        }
    }

    private var radiusAndShadow: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            heading("Radius and shadow")
            HStack(spacing: DS.Spacing.s3) {
                ForEach(Array(Self.shadows.enumerated()), id: \.offset) { item in
                    RoundedRectangle(cornerRadius: DS.Radius.xl2, style: .continuous)
                        .fill(DS.Color.panel)
                        .frame(width: DS.Spacing.s12, height: DS.Spacing.s12)
                        .dsShadow(item.element.level, cornerRadius: DS.Radius.xl2)
                        .overlay { Text(item.element.name).textStyle(.sansXs, tone: .tertiary) }
                }
            }
            .padding(DS.Spacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.sheet, in: RoundedRectangle(cornerRadius: DS.Radius.xl3, style: .continuous))
        }
    }
}

#Preview("Design Tokens - Light") {
    DesignTokensPreview()
        .preferredColorScheme(.light)
}

#Preview("Design Tokens - Dark") {
    DesignTokensPreview()
        .preferredColorScheme(.dark)
}
