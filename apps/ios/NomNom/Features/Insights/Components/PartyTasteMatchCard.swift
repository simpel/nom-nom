import SwiftUI

/// How well each member's ratings match the meals the party served, as a RatingList:
/// the header figure and the Bar `xs` are the party's average score over its last
/// `PartyTasteMatchCard.recentMeals` rated meals, then one RatingRow per member with
/// their match (0–100) as ScoreValue `xs` and the change since their earlier meals as
/// a delta Badge. Tapping a row calls `onSelectMember`.
struct PartyTasteMatchCard: View {
    /// The window the party average covers (a data window, not a design value).
    static let recentMeals = 20

    let matches: [MemberTasteMatch]
    /// The party's average score over its recent meals, 0–1; nil hides the meter.
    var partyAverage: Double?
    var onSelectMember: ((MemberTasteMatch) -> Void)? = nil

    private var averageFigure: Int? { partyAverage.map { Int(($0 * 100).rounded()) } }

    private var entries: [RatingListEntry] {
        matches.map { item in
            RatingListEntry(
                id: item.ref,
                name: item.name,
                score: Double(item.matchScore) / 100,
                delta: item.trendDelta,
                onTap: onSelectMember.map { select in { select(item) } }
            )
        }
    }

    var body: some View {
        if matches.isEmpty {
            DSSection("Taste match") {
                // EmptyState README copy for a chart without enough data.
                EmptyState("Not enough meals yet", message: "Taste match needs a few rated meals from each member.")
            }
        } else {
            RatingList(entries: entries, title: "Taste match", trailing: averageFigure.map { "Avg \($0)" }) {
                if let averageFigure {
                    Bar(
                        value: Double(averageFigure),
                        size: .xs,
                        label: "Party average \(averageFigure) over the last \(Self.recentMeals) meals"
                    )
                }
            }
        }
    }
}

#Preview {
    PartyTasteMatchCard(matches: [
        MemberTasteMatch(
            ref: .account(UUID()), name: "Anna", matchScore: 88, ratedMealsCount: 6,
            trend: .down, trendDelta: -12, explanation: nil
        ),
        MemberTasteMatch(
            ref: .account(UUID()), name: "Joel", matchScore: 95, ratedMealsCount: 8,
            trend: .up, trendDelta: 10, explanation: nil
        ),
    ], partyAverage: 0.78) { _ in }
    .padding(DS.Spacing.gutter)
    .background(DS.Color.bg)
}
