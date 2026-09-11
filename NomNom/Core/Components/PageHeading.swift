import SwiftUI

/// Clean, editorial page heading for root screens with a specific, left-aligned primary action button.
/// Standardized with NomNom's signature Newsreader heading font.
struct PageHeading: View {
    let title: String
    var actionTitle: String? = nil
    var actionSystemImage: String = "plus"
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(AppTypography.pageTitleFont)
                .foregroundStyle(DS.Color.textPrimary)

            Spacer()

            if let actionTitle, let onAction {
                AppButton(
                    actionTitle,
                    systemImage: actionSystemImage,
                    variant: .primary,
                    style: .normal,
                    size: .sm,
                    action: onAction
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NomNomPreview { _ in
        VStack(alignment: .leading, spacing: 24) {
            PageHeading(title: "Meals", actionTitle: "Add meal", onAction: {})
            PageHeading(title: "Recipes", actionTitle: "Add recipe", onAction: {})
            PageHeading(title: "Parties", actionTitle: "New party", onAction: {})
        }
        .padding()
    }
}
