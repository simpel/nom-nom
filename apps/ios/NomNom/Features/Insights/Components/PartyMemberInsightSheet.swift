import SwiftUI

/// One member of a dinner party ("Nom Nom iOS" canvas, MemberSheet), as a BottomSheet:
/// the PersonHeaderRow ("Member since Mar 2026 · 18 meals rated here"), two compact
/// ScoreCards (their average here, and with Pro their taste match), a ProCard "Cooking for
/// Anna" with the AI tip and recipes they will love, then with Pro their highest and lowest here.
struct PartyMemberInsightSheet: View {
    let memberRef: RaterRef
    let partyID: UUID

    @Environment(FoodStore.self) private var store
    @Environment(EntitlementStore.self) private var entitlements
    @State private var showProfile = false

    init(memberRef: RaterRef, partyID: UUID) {
        self.memberRef = memberRef
        self.partyID = partyID
    }

    init(member: MemberTasteMatch, partyID: UUID) {
        self.init(memberRef: member.ref, partyID: partyID)
    }

    private var name: String { store.firstName(for: memberRef) }

    private var tasteMatch: MemberTasteMatch? {
        store.memberTasteMatches(forParty: partyID).first { $0.ref == memberRef }
    }

    private var average: FoodStore.PartyScoreStats? {
        store.partyAverageScore(partyID: partyID, for: memberRef, limit: .max)
    }

    private var history: (highest: [PartyMemberMealRecord], lowest: [PartyMemberMealRecord]) {
        store.memberPartyDinnerHistory(for: memberRef, partyID: partyID)
    }

    var body: some View {
        NavigationStack {
            SheetBody {
                PartyMemberHeaderRow(memberRef: memberRef, partyID: partyID, ratedCount: average?.count ?? 0) {
                    showProfile = true
                }

                HStack(alignment: .top, spacing: DS.Spacing.s3) {
                    ScoreCard(score: average?.score, layout: .compact, title: "Average here")
                    // Taste match is an insight, so it is Pro only.
                    if entitlements.hasProAccess {
                        ScoreCard(
                            score: tasteMatch.map { Double($0.matchScore) / 100 },
                            verdict: tasteMatch.map { Self.matchVerdict($0.matchScore) },
                            layout: .compact,
                            title: "Taste match",
                            delta: tasteMatch?.trendDelta
                        )
                    }
                }

                PartyMemberCookingForSection(memberRef: memberRef, name: name, partyID: partyID)

                // Their highest and lowest meals are derived from their history, so Pro only.
                if entitlements.hasProAccess {
                    PartyMemberPartyRatingsSection(
                        memberRef: memberRef,
                        memberName: name,
                        highest: history.highest,
                        lowest: history.lowest
                    )
                }
            }
            .screenTitle(name, displayMode: .inline)
            .sheetCloseToolbar()
            .navigationDestination(isPresented: $showProfile) {
                PersonDetailView(raterRef: memberRef)
            }
        }
        .dsSheet()
    }

    /// How close their taste runs to the party's (DS-GAPS.md, "Taste match verdicts").
    static func matchVerdict(_ score: Int) -> String {
        switch score {
        case 85...: return "Close"
        case 65..<85: return "Near"
        default: return "Apart"
        }
    }
}
