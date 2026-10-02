import SwiftUI

/// The Insights tab's body for one party: the AI summary, then (Pro) taste match, the
/// health blocks and AI recipe recommendations, `spacing-7` apart on `bg` with
/// `spacing-4` gutters (README "Layout").
struct InsightsDashboardView: View {
    let partyID: UUID
    let insights: PartyInsights?
    let healthInsights: PartyHealthInsights?
    let partyTasteMatches: [MemberTasteMatch]

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
            VStack(alignment: .leading, spacing: DS.Spacing.block) {
                EditorialTextView(segments: combinedSummary)

                ProGate {
                    VStack(alignment: .leading, spacing: DS.Spacing.block) {
                        PartyTasteMatchCard(matches: partyTasteMatches) { member in
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

                        if let recommendations = insights?.recommendations, !recommendations.isEmpty {
                            RecipeShelf("AI recipe recommendations", items: recommendations) {
                                RecommendationShelfCard(rec: $0)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s3)
            .padding(.bottom, DS.Spacing.s11)
        }
        .background(DS.Color.bg)
        .sheet(item: $selectedMember) { member in
            PartyMemberInsightSheet(member: member, partyID: partyID)
        }
    }
}
