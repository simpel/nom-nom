import SwiftUI

struct InsightsDashboardView: View {
    let partyID: UUID
    let insights: PartyInsights?
    let healthInsights: PartyHealthInsights?
    let trendData: [(date: Date, averageScore: Double)]
    let memberTrendSeries: [MemberTrendSeries]
    let partyTasteMatches: [MemberTasteMatch]
    let mealsLoggedCount: Int

    @State private var selectedMember: MemberTasteMatch?

    var combinedSummary: [GuestNoteSegment] {
        let text = insights?.summarySentence ?? ""
        if text.isEmpty {
            return [GuestNoteSegment(text: "Check back later when enough meals have been rated by the party.", tone: .neutral)]
        }
        return MarkdownSegmentParser.parse(text)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.section) {
                // 1. Editorial summary text combined with flavor profile
                EditorialTextView(segments: combinedSummary)
                    .padding(.top, DS.Spacing.sm)
                    .padding(.horizontal, DS.Spacing.screenHorizontal)

                // 2-4. Health metrics, recommendations — Pro
                ProGate {
                    VStack(alignment: .leading, spacing: DS.Spacing.section) {
                        PartyTasteMatchCard(matches: partyTasteMatches) { member in
                            selectedMember = member
                        }
                        .padding(.horizontal, DS.Spacing.screenHorizontal)

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
                            .padding(.horizontal, DS.Spacing.screenHorizontal)
                        }

                        if let recommendations = insights?.recommendations, !recommendations.isEmpty {
                            RecipeShelf("AI recipe recommendations", items: recommendations) {
                                RecommendationShelfCard(rec: $0)
                            }
                            .padding(.horizontal, DS.Spacing.gutter)
                        }
                    }
                }
            }
            .padding(.bottom, DS.Spacing.screenBottom)
        }
        .background(DS.Color.bg)
        .sheet(item: $selectedMember) { member in
            PartyMemberInsightSheet(member: member, partyID: partyID)
        }
    }
}
