import SwiftUI

/// The Meals tab before anything is logged: EmptyState `screen` (README case "First
/// run — nothing logged") with "Log a meal". The current party, when there is one, is
/// named in the message.
struct MealsEmptyStateView: View {
    @Environment(FoodStore.self) private var store
    let onLogMeal: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                EmptyState(
                    "No meals yet",
                    message: message,
                    icon: "fork.knife",
                    layout: .screen,
                    action: EmptyStateAction("Log a meal", perform: onLogMeal)
                )
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
            return "Log tonight\u{2019}s dinner and serve it to \(party.name)."
        }
        return "Log tonight\u{2019}s dinner and it will show up here."
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
