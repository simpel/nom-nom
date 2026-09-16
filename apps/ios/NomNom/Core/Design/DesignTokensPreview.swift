import SwiftUI

/// Preview surface rendering every Stone, Pine, and Semantic token side-by-side in Light and Dark modes.
struct DesignTokensPreview: View {
    private let roles: [(name: String, color: Color, textColor: Color)] = [
        ("bg", DS.Color.bg, DS.Color.textPrimary),
        ("panel", DS.Color.panel, DS.Color.textPrimary),
        ("sunken", DS.Color.sunken, DS.Color.textPrimary),
        ("line", DS.Color.line, DS.Color.textPrimary),
        ("lineStrong", DS.Color.lineStrong, DS.Color.textPrimary),
        ("textPrimary", DS.Color.textPrimary, DS.Color.panel),
        ("textSecondary", DS.Color.textSecondary, DS.Color.panel),
        ("textTertiary", DS.Color.textTertiary, DS.Color.panel),
        ("accent", DS.Color.accent, DS.Color.panel),
        ("accentText", DS.Color.accentText, DS.Color.panel),
        ("accentSoft", DS.Color.accentSoft, DS.Color.textPrimary)
    ]

    private let stoneRamp: [(name: String, color: Color)] = [
        ("stone0", DS.Color.Stone.stone0),
        ("stone25", DS.Color.Stone.stone25),
        ("stone50", DS.Color.Stone.stone50),
        ("stone100", DS.Color.Stone.stone100),
        ("stone200", DS.Color.Stone.stone200),
        ("stone300", DS.Color.Stone.stone300),
        ("stone400", DS.Color.Stone.stone400),
        ("stone500", DS.Color.Stone.stone500),
        ("stone600", DS.Color.Stone.stone600),
        ("stone700", DS.Color.Stone.stone700),
        ("stone800", DS.Color.Stone.stone800),
        ("stone900", DS.Color.Stone.stone900),
        ("stone950", DS.Color.Stone.stone950),
        ("stone1000", DS.Color.Stone.stone1000)
    ]

    private let pineRamp: [(name: String, color: Color)] = [
        ("pine50", DS.Color.Pine.pine50),
        ("pine100", DS.Color.Pine.pine100),
        ("pine200", DS.Color.Pine.pine200),
        ("pine300", DS.Color.Pine.pine300),
        ("pine400", DS.Color.Pine.pine400),
        ("pine500", DS.Color.Pine.pine500),
        ("pine600", DS.Color.Pine.pine600),
        ("pine700", DS.Color.Pine.pine700),
        ("pine800", DS.Color.Pine.pine800),
        ("pine900", DS.Color.Pine.pine900)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Design System Tokens")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DS.Color.textPrimary)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Semantic Roles")
                        .font(.headline)
                        .foregroundStyle(DS.Color.textPrimary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 95), spacing: 8)], spacing: 8) {
                        ForEach(roles, id: \.name) { role in
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                                    .fill(role.color)
                                    .frame(height: 38)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                                            .strokeBorder(DS.Color.lineStrong.opacity(0.3), lineWidth: 1)
                                    )
                                Text(role.name)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(DS.Color.textSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Stone Ramp (Hue 258°)")
                        .font(.headline)
                        .foregroundStyle(DS.Color.textPrimary)

                    HStack(spacing: 2) {
                        ForEach(stoneRamp, id: \.name) { step in
                            Rectangle()
                                .fill(step.color)
                                .frame(height: 28)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Pine Ramp (Hue 193°)")
                        .font(.headline)
                        .foregroundStyle(DS.Color.textPrimary)

                    HStack(spacing: 2) {
                        ForEach(pineRamp, id: \.name) { step in
                            Rectangle()
                                .fill(step.color)
                                .frame(height: 28)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous))
                }
            }
            .padding(16)
        }
        .background(DS.Color.bg)
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
