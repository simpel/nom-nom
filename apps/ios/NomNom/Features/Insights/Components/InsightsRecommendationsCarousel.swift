import SwiftUI

struct InsightsRecommendationsCarousel: View {
    let recommendations: [PartyInsightRecommendation]
    
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
                            if let dishID = rec.dishID {
                                NavigationLink(value: InsightsRoute.dish(dishID)) {
                                    RecommendationCard(rec: rec)
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
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text(rec.title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(DS.Color.textPrimary)
                .lineLimit(2)
            
            if let cuisine = rec.cuisine {
                Text(cuisine.capitalized)
                    .font(.caption)
                    .foregroundStyle(DS.Color.accentText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DS.Color.accentSoft)
                    .clipShape(Capsule())
            }
            
            Text(rec.description)
                .font(.caption)
                .foregroundStyle(DS.Color.textSecondary)
                .lineLimit(3)
            
            Spacer(minLength: 0)
        }
        .padding(DS.Spacing.md)
        .frame(width: 220, height: 160, alignment: .topLeading)
        .background(DS.Color.panel)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
