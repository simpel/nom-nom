import SwiftUI

/// Personal taste profile + health trend for one rater, shown on `PersonDetailView`.
/// Works identically for "my profile" and viewing someone else's — both just a `RaterRef`.
struct ProfileInsightsSection: View {
    let raterRef: RaterRef

    @Environment(FoodStore.self) private var store
    @State private var flavorProfile: [FlavorProfileEntry] = []

    private var tasteProfile: RaterTasteProfile? {
        store.tasteProfile(for: raterRef)
    }

    private var healthInsights: PartyHealthInsights? {
        store.healthInsights(for: raterRef)
    }

    var body: some View {
        if tasteProfile != nil || healthInsights != nil {
            ProCard(
                "Insights",
                teaser: "See this taste profile, the health trend and the flavours behind it."
            ) {
                VStack(alignment: .leading, spacing: DS.Spacing.block) {
                    if let tasteProfile {
                        tasteProfileCard(tasteProfile)
                        if !tasteProfile.ratingDistribution.isEmpty {
                            SegmentedBar(
                                .reactions(tasteProfile.ratingDistribution),
                                legend: .rows,
                                title: "Ratings given",
                                trailing: "\(tasteProfile.totalRatingsGiven)"
                            )
                        }
                    }

                    if let healthInsights {
                        healthTrendChart(healthInsights)

                        if let macros = healthInsights.averageMacros {
                            AverageMacrosCard(macros: macros)
                        }
                    }

                    FlavorProfileCard(entries: flavorProfile)
                }
            }
            .task(id: raterRef) {
                flavorProfile = (try? await store.fetchFlavorProfile(for: raterRef)) ?? []
            }
        }
    }

    private func healthTrendChart(_ healthInsights: PartyHealthInsights) -> some View {
        TrendChart(
            total: healthInsights.healthScoreTrend.map { TrendPoint(date: $0.date, value: $0.averageHealthScore / 100) },
            totalName: "Health"
        )
    }

    /// The average score this rater gives (ScoreValue `sm`) and their top cuisines.
    private func tasteProfileCard(_ profile: RaterTasteProfile) -> some View {
        SectionCard("Average score given", trailing: ratingsText(profile.totalRatingsGiven)) {
            ScoreValue(score: profile.averageScoreGiven, size: .sm)
            if !profile.topCuisines.isEmpty {
                Text("Top cuisines: " + profile.topCuisines.map(\.cuisine).joined(separator: ", "))
                    .textStyle(.sansSm, tone: .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func ratingsText(_ count: Int) -> String {
        count == 1 ? "1 rating" : "\(count) ratings"
    }
}
