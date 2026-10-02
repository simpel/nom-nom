import SwiftUI

/// Insights for an arbitrary party (not necessarily `store.currentParty`), shown inline on
/// `PartyDetailView`. Reuses the same insight components and gating as the Insights tab.
struct PartyInsightsSection: View {
    let partyID: UUID

    @Environment(FoodStore.self) private var store
    @State private var insights: PartyInsights?
    @State private var flavorProfile: [FlavorProfileEntry] = []
    @State private var selectedMember: MemberTasteMatch?

    private var healthInsights: PartyHealthInsights? {
        store.healthInsights(forParty: partyID)
    }

    private var trendData: [(date: Date, averageScore: Double)] {
        store.trendline(forParty: partyID)
    }

    /// Member lines, coloured by their stable position in the store's rater order.
    private var memberSeries: [TrendSeries] {
        store.memberTrendlines(forParty: partyID).enumerated().map { index, member in
            TrendSeries(
                id: member.ref,
                name: member.name,
                colorIndex: index,
                points: member.points.map { TrendPoint(date: $0.date, value: $0.score / 100) }
            )
        }
    }

    var body: some View {
        DSSection("Insights") {
            ProGate {
                VStack(alignment: .leading, spacing: DS.Spacing.block) {
                    TrendChart(
                        total: trendData.map { TrendPoint(date: $0.date, value: $0.averageScore / 100) },
                        series: memberSeries,
                        visibleDays: 14
                    )

                    PartyTasteMatchCard(matches: store.memberTasteMatches(forParty: partyID, insights: insights)) { member in
                        selectedMember = member
                    }

                    if let health = healthInsights {
                        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
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
        .sheet(item: $selectedMember) { member in
            PartyMemberInsightSheet(member: member, partyID: partyID)
        }
    }
}
