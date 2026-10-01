import SwiftUI

/// Horizontal recipe shelf displaying personalized recommendations for a specific party member,
/// featuring dual-compatibility badges (user appeal + party fit) and reusing the centralized `RecipeCard`.
struct PartyMemberRecommendationsShelf: View {
    let memberName: String
    let recommendations: [PartyMemberRecipeRecommendation]

    var body: some View {
        if !recommendations.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recipes \(memberName) Will Love")
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 14) {
                        ForEach(recommendations) { item in
                            NavigationLink {
                                RecipeDetailView(recipe: item.recipe)
                            } label: {
                                MinimalRecipeCard(recipe: item.recipe)
                                    .frame(width: 156, height: 220, alignment: .top)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.screenHorizontal)
                }
                .padding(.horizontal, -DS.Spacing.screenHorizontal)
            }
        }
    }
}
