import SwiftUI

/// The recipe's Facts in a Card (screen anatomy: after the photos): time, method,
/// servings and the household's rotation goal. Shows nothing when the recipe has none.
struct RecipeDetailFacts: View {
    let recipe: Recipe

    @Environment(FoodStore.self) private var store

    private var facts: [Fact] {
        [
            recipe.effort.map { Fact(label: "Time", value: $0.label) },
            store.cookingMethod(for: recipe).map { Fact(label: "Method", value: $0.name) },
            recipe.serves.map { Fact(label: "Serves", value: "\($0)") },
            store.averageRotation(forDish: recipe.id).map { Fact(label: "Rotation", value: Self.rotationLabel($0)) },
        ]
        .compactMap { $0 }
    }

    /// Sentence case, as the DS writes every label.
    static func rotationLabel(_ goal: RotationGoal) -> String {
        switch goal {
        case .oneAndDone: return "One & done"
        case .sometimes: return "Sometimes"
        case .staple: return "Staple"
        }
    }

    var body: some View {
        if !facts.isEmpty {
            Card { Facts(facts) }
        }
    }
}
