import SwiftUI

/// Insights for an arbitrary party (not necessarily `store.currentParty`) on
/// `PartyInsightsView` (a ProView behind a ProGate): the AI summary, then ratings over time (an unframed TrendChart bleeding to the screen edges), taste
/// match, the health blocks, the ingredient profile and AI recipe recommendations,
/// `spacing-7` apart. Each block carries its own section header. The section owns the
/// `gutter` and the chart bleeds past it.
struct PartyInsightsSection: View {
    let partyID: UUID

    @Environment(FoodStore.self) private var store
    @State private var insights: PartyInsights?
    @State private var hasLoadedInsights = false
    @State private var flavorProfile: [FlavorProfileEntry] = []
    @State private var selectedMember: MemberTasteMatch?

    /// Days in view before the chart scrolls (a data window, not a design value).
    private static let visibleDays = 14

    private var healthInsights: PartyHealthInsights? {
        store.healthInsights(forParty: partyID)
    }

    private var trendData: [(date: Date, averageScore: Double)] {
        store.trendline(forParty: partyID)
    }

    /// Member lines. README "Colour": "assign `chart-series1…7` by a stable index per
    /// party member, never cycled" — the index is the member's position in the party's
    /// member list, so a colour stays with a person whether or not others have rated.
    /// Raters who are not members (eaters) follow after the members.
    private var memberSeries: [TrendSeries] {
        let memberIDs = store.members(of: partyID).map(\.id)
        return store.memberTrendlines(forParty: partyID).enumerated().map { offset, member in
            let index = memberIDs.firstIndex { RaterRef.account($0) == member.ref } ?? memberIDs.count + offset
            return TrendSeries(
                id: member.ref,
                name: member.name,
                colorIndex: index,
                points: member.points.map { TrendPoint(date: $0.date, value: $0.score / 100) }
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.block) {
            if hasLoadedInsights {
                EditorialTextView(insightSummary: insights?.summarySentence)
            }

            DSSection("Ratings over time") {
                TrendChart(
                    total: trendData.map { TrendPoint(date: $0.date, value: $0.averageScore / 100) },
                    series: memberSeries,
                    visibleDays: Self.visibleDays,
                    framed: false
                )
                .padding(.horizontal, -DS.Spacing.gutter)
            }

            blocks
        }
        .padding(.horizontal, DS.Spacing.gutter)
        .task(id: partyID) {
            insights = try? await store.fetchInsights(for: partyID)
            hasLoadedInsights = true
            flavorProfile = (try? await store.fetchFlavorProfile(forParty: partyID)) ?? []
        }
        .sheet(item: $selectedMember) { member in
            PartyMemberInsightSheet(member: member, partyID: partyID)
        }
    }

    /// Everything under the chart, inside the gutter.
    @ViewBuilder
    private var blocks: some View {
        PartyTasteMatchCard(
            matches: store.memberTasteMatches(forParty: partyID, insights: insights),
            partyAverage: store.recentAverageScore(forParty: partyID, limit: PartyTasteMatchCard.recentMeals)
        ) { member in
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
            RecipeShelf("AI recipe recommendations", items: recommendations) {
                RecommendationShelfCard(rec: $0)
            }
        }
    }
}
