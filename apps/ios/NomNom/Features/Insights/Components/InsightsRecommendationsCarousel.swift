import SwiftUI

struct InsightsRecommendationsCarousel: View {
    let recommendations: [PartyInsightRecommendation]
    @Environment(FoodStore.self) private var store

    var body: some View {
        if recommendations.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                Text("AI Recipe Recommendations")
                    .textStyle(.sansLg, weight: .semibold)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: DS.Spacing.s4) {
                        ForEach(recommendations) { rec in
                            if let dishID = rec.dishID, let recipe = store.recipe(dishID) {
                                NavigationLink(value: InsightsRoute.dish(dishID)) {
                                    RecipeCard(recipe: recipe, category: rec.cuisine) {
                                        Text(rec.description)
                                            .textStyle(.sansSm, tone: .secondary)
                                            .lineLimit(3)
                                    }
                                    .frame(width: DS.Spacing.s48)
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

/// A recommendation with no recipe yet: RecipeCard's layout (PhotoCard `md` on the
/// cuisine photo, category SectionHeader, two-line title) plus the description.
private struct RecommendationCard: View {
    let rec: PartyInsightRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s1_5) {
            PhotoCard(.none(cuisine: rec.cuisine), size: .md, fillsWidth: true, accessibilityLabel: rec.title)

            VStack(alignment: .leading, spacing: DS.Spacing.s0_5) {
                SectionHeader(title: rec.cuisine ?? "Recipe")
                Text(rec.title)
                    .textStyle(.sansSm, weight: .semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(minHeight: DS.Spacing.s14, alignment: .topLeading)

            Text(rec.description)
                .textStyle(.sansSm, tone: .secondary)
                .lineLimit(3)
        }
        .frame(width: DS.Spacing.s48, alignment: .leading)
        .contentShape(Rectangle())
    }
}
