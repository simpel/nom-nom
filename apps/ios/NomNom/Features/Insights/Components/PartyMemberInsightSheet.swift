import SwiftUI

/// Contextual sheet showing an individual member's taste insights in relation to the current dinner party.
/// Presented as a standard modal sheet matching `MealRatingSheet`.
struct PartyMemberInsightSheet: View {
    let member: MemberTasteMatch
    let partyID: UUID

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var tipSegments: [GuestNoteSegment] {
        store.nextDinnerTipSegments(for: member.ref, partyID: partyID)
    }

    private var recommendations: [PartyMemberRecipeRecommendation] {
        store.memberPartyRecommendations(for: member.ref, partyID: partyID)
    }

    private var history: (highest: [PartyMemberMealRecord], lowest: [PartyMemberMealRecord]) {
        store.memberPartyDinnerHistory(for: member.ref, partyID: partyID)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.section) {
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        // Header: Name as heading alone
                        Text(member.name)
                            .font(Font.newsreader(.largeTitle, weight: .semibold))
                            .foregroundStyle(DS.Color.textPrimary)

                        // Editorial narrative (Newsreader serif with semantic highlights)
                        EditorialTextView(segments: tipSegments)
                    }
                    .padding(.top, DS.Spacing.xs)

                    // Recipes Member Will Love (Horizontal Scroll reusing MinimalRecipeCard)
                    PartyMemberRecommendationsShelf(
                        memberName: member.name,
                        recommendations: recommendations
                    )

                    // Personal Rating History in this Party (reusing startpage MealRow)
                    PartyMemberPartyRatingsSection(
                        memberRef: member.ref,
                        memberName: member.name,
                        highest: history.highest,
                        lowest: history.lowest
                    )
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .sheetCloseToolbar()
        }
    }
}
