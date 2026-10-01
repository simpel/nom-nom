// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// "Sharing & Visibility": a SectionCard with one public/private switch and a
/// line explaining what public means. Used by party and recipe editors.
struct VisibilityToggleCard: View {
    var title: String = "Sharing & Visibility"
    let label: String
    let message: String
    @Binding var isPublic: Bool

    var body: some View {
        SectionCard(title) {
            VStack(alignment: .leading, spacing: DS.Spacing.s1_5) {
                Toggle(isOn: $isPublic) {
                    Text(label).textStyle(.sansMd, weight: .semibold)
                }
                .nativeToggle()

                Text(message)
                    .textStyle(.sansXs, tone: .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

extension VisibilityToggleCard {
    /// The dinner party copy.
    static func party(isPublic: Binding<Bool>) -> VisibilityToggleCard {
        VisibilityToggleCard(
            label: "Make dinner party public",
            message: "When enabled, other foodies can discover and follow this dinner party.",
            isPublic: isPublic
        )
    }

    /// The recipe copy.
    static func recipe(isPublic: Binding<Bool>) -> VisibilityToggleCard {
        VisibilityToggleCard(
            label: "Make recipe public",
            message: "When enabled, other dinner parties and users can discover and cook this recipe.",
            isPublic: isPublic
        )
    }
}

private struct VisibilityToggleCardPreview: View {
    @State private var isPublic = true

    var body: some View {
        VStack(spacing: DS.Spacing.block) {
            VisibilityToggleCard.party(isPublic: $isPublic)
            VisibilityToggleCard.recipe(isPublic: .constant(false))
        }
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { VisibilityToggleCardPreview() }
#Preview("Dark") { VisibilityToggleCardPreview().preferredColorScheme(.dark) }
