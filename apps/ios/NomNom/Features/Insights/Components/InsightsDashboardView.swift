import SwiftUI

/// The Insights tab's body for one party, a Pro-only view: a ProView (`pro-soft` ground,
/// ProMark on top) with the AI summary, taste match, the health blocks and AI recipe
/// recommendations, `spacing-7` apart with `spacing-4` gutters (README "Layout"). Without
/// Pro, a ProGate blurs it behind the unlock card.
struct InsightsDashboardView: View {
    let partyID: UUID
    let insights: PartyInsights?
    let healthInsights: PartyHealthInsights?
    let partyTasteMatches: [MemberTasteMatch]
    /// The party average over its recent meals, 0–1 (PartyTasteMatchCard's meter).
    var partyAverage: Double?

    @State private var selectedMember: MemberTasteMatch?

    var body: some View {
        ProGate(
            "Insights are part of Nom Nom Pro",
            message: "See how your dinner party eats, side by side.",
            benefits: [
                "Your party\u{2019}s taste match, member by member",
                "Health, macros and flavours across your meals",
                "AI recipe recommendations"
            ]
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.block) {
                    ProMark()

                    EditorialTextView(insightSummary: insights?.summarySentence)

                    PartyTasteMatchCard(
                        matches: partyTasteMatches,
                        partyAverage: partyAverage
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

                    if let recommendations = insights?.recommendations, !recommendations.isEmpty {
                        RecipeShelf("AI recipe recommendations", items: recommendations) {
                            RecommendationShelfCard(rec: $0)
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.gutter)
                .padding(.top, DS.Spacing.s3)
                .padding(.bottom, DS.Spacing.s11)
            }
        }
        .proView()
        .sheet(item: $selectedMember) { member in
            PartyMemberInsightSheet(member: member, partyID: partyID)
        }
    }
}
