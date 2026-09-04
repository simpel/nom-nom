import SwiftUI

/// Clean key-value details table for a recipe: Created by, Cooking Time, Cuisine, Tags.
struct RecipeDetailInfoCard: View {
    let recipe: Recipe

    @Environment(FoodStore.self) private var store

    private var creatorName: String {
        if let profile = store.profiles[recipe.ownerID] {
            return profile.shownName
        }
        if recipe.ownerID == store.userID {
            return store.myProfile?.shownName ?? "You"
        }
        return "Someone"
    }

    var body: some View {
        SectionCard(title: "Details") {
            VStack(spacing: 12) {
                // Created by (clickable to view user profile)
                HStack {
                    Text("Created by")
                        .font(.subheadline)
                        .foregroundStyle(DS.Color.textSecondary)
                    Spacer()
                    NavigationLink {
                        PersonDetailView(raterRef: .account(recipe.ownerID))
                    } label: {
                        HStack(spacing: 6) {
                            Text(creatorName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(DS.Color.textPrimary)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Cooking Time / Effort
                if let effort = recipe.effort {
                    Divider().overlay(DS.Color.line.opacity(0.3))
                    HStack {
                        Text("Cooking Time")
                            .font(.subheadline)
                            .foregroundStyle(DS.Color.textSecondary)
                        Spacer()
                        BurnerMeter(effort: effort, showLabel: true)
                    }
                }

                // Cuisine
                if let cuisineName = Cuisine.formatDisplayName(recipe.cuisine) {
                    Divider().overlay(DS.Color.line.opacity(0.3))
                    HStack {
                        Text("Cuisine")
                            .font(.subheadline)
                            .foregroundStyle(DS.Color.textSecondary)
                        Spacer()
                        Text(cuisineName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(DS.Color.textPrimary)
                    }
                }

                // Tags
                if !recipe.tags.isEmpty {
                    Divider().overlay(DS.Color.line.opacity(0.3))
                    HStack(alignment: .top) {
                        Text("Tags")
                            .font(.subheadline)
                            .foregroundStyle(DS.Color.textSecondary)
                            .padding(.top, 2)
                        Spacer()
                        WrappingHStack {
                            ForEach(recipe.tags, id: \.self) { tag in
                                Chip(text: tag, systemImage: "tag", tint: DS.Color.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }
}
