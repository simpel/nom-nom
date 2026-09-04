import SwiftUI

/// Standardized uppercase section header with optional trailing accessory text.
/// Adheres to Nom Nom typography tokens and styling conventions.
struct SectionHeader: View {
    let title: String
    var trailingText: String? = nil
    var trailingColor: Color? = nil
    var horizontalPadding: CGFloat = 16

    init(
        _ title: String,
        trailingText: String? = nil,
        trailingColor: Color? = nil,
        horizontalPadding: CGFloat = 16
    ) {
        self.title = title
        self.trailingText = trailingText
        self.trailingColor = trailingColor
        self.horizontalPadding = horizontalPadding
    }

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.5)
                .foregroundStyle(DS.Color.textSecondary)

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(trailingColor ?? DS.Color.textSecondary)
            }
        }
        .padding(.horizontal, horizontalPadding)
    }
}

#Preview {
    NomNomPreview {
        VStack(spacing: 20) {
            SectionHeader("Popular Recipes")
            SectionHeader("Matching Recipes", trailingText: "12 found")
        }
    }
}
