import SwiftUI

/// Empty state for the Meals tab when no meals have been recorded yet: the current
/// party's name (when there is one) over an EmptyState with a "Log a meal" button.
struct MealsEmptyStateView: View {
    @Environment(FoodStore.self) private var store
    let onLogMeal: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: DS.Spacing.s4) {
                    if let partyName = store.currentParty?.name {
                        Text(partyName)
                            .textStyle(.serifLg)
                            .multilineTextAlignment(.center)
                    }

                    EmptyState(
                        "Log your first meal",
                        message: message,
                        action: EmptyStateAction(title: "Log a meal", appearance: .solid, perform: onLogMeal)
                    )
                }
                .padding(.horizontal, DS.Spacing.gutter)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background(DS.Color.bg)
    }

    private var message: String {
        if let party = store.currentParty {
            return "No meals have been served to \(party.name) yet. Log tonight\u{2019}s dinner and serve it to this party."
        }
        return "Snap a photo of tonight\u{2019}s dinner, give it a name and mark how it went down."
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
