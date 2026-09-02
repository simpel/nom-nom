import SwiftUI

/// Section listing favorite or disliked dishes for a person.
struct PersonDishRatingsList: View {
    let title: String
    let dishes: [Dish]
    let isDisliked: Bool

    @Environment(FoodStore.self) private var store

    init(title: String, dishes: [Dish], isDisliked: Bool = false) {
        self.title = title
        self.dishes = dishes
        self.isDisliked = isDisliked
    }

    var body: some View {
        SectionCard("\(title) (\(dishes.count))") {
            VStack(spacing: 8) {
                ForEach(dishes) { dish in
                    NavigationLink {
                        RecipeDetailView(recipeID: dish.id)
                    } label: {
                        HStack(spacing: 12) {
                            let servings = store.servings(of: dish.id)
                            RemoteMealPhoto(path: servings.first?.photoPath, cornerRadius: AppRadius.photo)
                                .frame(width: 44, height: 44)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(dish.name)
                                    .font(.inter(.body, weight: .semibold))
                                    .foregroundStyle(.primary)
                                if isDisliked {
                                    Text("Rated poorly")
                                        .font(.inter(.caption))
                                        .foregroundStyle(.red)
                                } else if !dish.tags.isEmpty {
                                    Text(dish.tags.joined(separator: " · "))
                                        .font(.inter(.caption))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)

                    if dish.id != dishes.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}
