import SwiftUI

/// Header card for RecipeDetailView showing title, cook count, last cooked date, tags, effort,
/// and the primary action button to cook/log this recipe.
struct RecipeHeaderCard: View {
    let recipe: Recipe
    let history: [Meal]
    let onCook: () -> Void

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.name)
                        .font(.inter(.title2, weight: .bold))

                    HStack(spacing: 8) {
                        Text(history.isEmpty
                             ? "Never cooked"
                             : "Cooked \(history.count) time\(history.count == 1 ? "" : "s")")
                            .font(.inter(.subheadline))
                            .foregroundStyle(.secondary)

                        if let last = history.first?.eatenOn {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text("Last \(last, format: .dateTime.day().month(.abbreviated).year())")
                                .font(.inter(.subheadline))
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 8) {
                        if let cuisineName = Cuisine.formatDisplayName(recipe.cuisine) {
                            Chip(text: cuisineName, systemImage: "fork.knife", tint: DS.Color.accentText)
                        }
                        if let effort = recipe.effort {
                            BurnerMeter(effort: effort, showLabel: true)
                        }
                    }
                    .padding(.top, 2)
                }

                if !recipe.tags.isEmpty {
                    WrappingHStack {
                        ForEach(recipe.tags, id: \.self) { tag in
                            Chip(text: tag, systemImage: "tag", tint: DS.Color.textSecondary)
                        }
                    }
                }

                Button(action: onCook) {
                    HStack {
                        Spacer()
                        Label("Cook this recipe", systemImage: "fork.knife")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
            }
        }
    }
}
