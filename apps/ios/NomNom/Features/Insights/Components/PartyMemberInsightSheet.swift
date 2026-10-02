import SwiftUI

/// A member's taste insights for one dinner party, as a BottomSheet: their name and the
/// AI tip, recipes they will love, then their highest and lowest rated dinners here.
struct PartyMemberInsightSheet: View {
    let member: MemberTasteMatch
    let partyID: UUID

    @Environment(FoodStore.self) private var store

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
            SheetBody {
                // PageHeader spacing: `spacing-2` between the parts.
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Text(member.name)
                        .textStyle(.serifLg)
                        .accessibilityAddTraits(.isHeader)
                    EditorialTextView(segments: tipSegments)
                }

                RecipeShelf("Recipes \(member.name) will love", recipes: recommendations.map(\.recipe)) {
                    RecipeDetailView(recipe: $0)
                }

                PartyMemberPartyRatingsSection(
                    memberRef: member.ref,
                    memberName: member.name,
                    highest: history.highest,
                    lowest: history.lowest
                )
            }
            .sheetCloseToolbar()
        }
        .dsSheet()
    }
}
