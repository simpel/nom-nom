import SwiftUI

/// Empty state for the Meals tab when no meals have been recorded yet.
///
/// Features a fanned-out arc of category food photos, editorial copy,
/// and a prominent primary action button to log the first meal.
struct MealsEmptyStateView: View {
    @Environment(FoodStore.self) private var store
    let onLogMeal: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: DS.Spacing.section) {
                    Spacer(minLength: 20)

                    if let partyName = store.currentParty?.name {
                        Text(partyName)
                            .font(AppTypography.pageTitleFont)
                            .foregroundStyle(DS.Color.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    CategoryPhotoArcView()
                        .padding(.vertical, DS.Spacing.xs)

                    VStack(spacing: 10) {
                        Text("Nothing logged yet")
                            .font(AppTypography.displayL)
                            .foregroundStyle(DS.Color.textPrimary)

                        descriptionText
                            .font(AppTypography.bodyM)
                            .foregroundStyle(DS.Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 28)
                    }

                    AppButton(
                        "Log a meal",
                        variant: .primary,
                        style: .normal,
                        size: .xl,
                        isFullWidth: true,
                        action: onLogMeal
                    )
                    .frame(maxWidth: 320)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background(DS.Color.bg)
    }

    // MARK: - Description

    private var descriptionText: some View {
        Group {
            if let party = store.currentParty {
                Text("No meals have been served to \(party.name) yet. Log tonight's dinner and serve it to this party!")
            } else {
                Text("Snap a photo of tonight's dinner, give it a name and mark how it went down.")
            }
        }
    }
}

#Preview("No Party") {
    NomNomPreview(store: .empty) {
        MealsEmptyStateView(onLogMeal: {})
    }
}

#Preview("With Party") {
    NomNomPreview {
        MealsEmptyStateView(onLogMeal: {})
    }
}
