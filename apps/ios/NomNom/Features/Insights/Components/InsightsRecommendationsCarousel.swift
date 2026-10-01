import SwiftUI

struct InsightsRecommendationsCarousel: View {
    let recommendations: [PartyInsightRecommendation]
    @Environment(FoodStore.self) private var store
    
    var body: some View {
        if recommendations.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text("AI Recipe Recommendations")
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.md) {
                        ForEach(recommendations) { rec in
                            if let dishID = rec.dishID, let recipe = store.recipe(dishID) {
                                NavigationLink(value: InsightsRoute.dish(dishID)) {
                                    RecipeCard(recipe: recipe, subtitle: rec.cuisine) {
                                        Text(rec.description)
                                            .font(.caption)
                                            .foregroundStyle(DS.Color.textSecondary)
                                            .lineLimit(3)
                                    }
                                    .frame(width: 160)
                                }
                                .buttonStyle(.plain)
                            } else {
                                RecommendationCard(rec: rec)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct RecommendationCard: View {
    let rec: PartyInsightRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RecipeImageView(photoPath: nil, cuisine: rec.cuisine, cornerRadius: AppRadius.photo)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo))
            .aspectRatio(1, contentMode: .fit)
            .frame(minWidth: 0, maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 2) {
                if let cuisine = rec.cuisine {
                    Text(cuisine.uppercased())
                        .font(.caption2.weight(.medium))
                        .tracking(0.4)
                        .foregroundStyle(DS.Color.accentText)
                        .lineLimit(1)
                }
                
                Text(rec.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(rec.description)
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineLimit(3)
                    .padding(.top, 2)
            }
            .frame(height: 58, alignment: .topLeading)
        }
        .frame(width: 160)
        .contentShape(Rectangle())
    }
}
