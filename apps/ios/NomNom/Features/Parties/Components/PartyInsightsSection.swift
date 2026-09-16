import SwiftUI

/// Insights for an arbitrary party (not necessarily `store.currentParty`), shown inline on
/// `PartyDetailView`. Reuses the same insight components and gating as the Insights tab.
struct PartyInsightsSection: View {
    let partyID: UUID

    @Environment(FoodStore.self) private var store
    @State private var insights: PartyInsights?
    @State private var flavorProfile: [FlavorProfileEntry] = []

    private var healthInsights: PartyHealthInsights? {
        store.healthInsights(forParty: partyID)
    }

    private var trendData: [(date: Date, averageScore: Double)] {
        store.trendline(forParty: partyID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.section) {
            Text("Insights")
                .font(.headline)
                .foregroundStyle(DS.Color.textPrimary)

            ProGate {
                VStack(alignment: .leading, spacing: DS.Spacing.section) {
                    PartyTasteTrendChart(totalTrend: trendData, memberSeries: store.memberTrendlines(forParty: partyID))

                    if let health = healthInsights {
                        VStack(alignment: .leading, spacing: DS.Spacing.md) {
                            PartyHealthDistributionCard(distribution: health.healthTierDistribution)

                            PartyHealthStrengthsCard(
                                topStrengths: health.topStrengths,
                                topConsiderations: health.topConsiderations
                            )

                            if let macros = health.averageMacros {
                                AverageMacrosCard(macros: macros)
                            }
                        }
                    }

                    if let profile = insights?.foodProfile {
                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            Text("Flavor Profile")
                                .font(.headline)
                                .foregroundStyle(DS.Color.textPrimary)

                            Text(profile)
                                .font(.body)
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                    }

                    FlavorProfileCard(entries: flavorProfile)

                    if let recommendations = insights?.recommendations, !recommendations.isEmpty {
                        InsightsRecommendationsCarousel(recommendations: recommendations)
                    }
                }
            }
        }
        .task(id: partyID) {
            insights = try? await store.fetchInsights(for: partyID)
            flavorProfile = (try? await store.fetchFlavorProfile(forParty: partyID)) ?? []
        }
    }
}
