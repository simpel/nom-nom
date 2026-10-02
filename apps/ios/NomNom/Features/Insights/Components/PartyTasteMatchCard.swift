import SwiftUI

/// How well each member's ratings match the meals the party served: a DSSection over a
/// `Card(layout: .list)` of ListRows. Each row is the member's Avatar, their name over
/// a `primary` Bar of the match (0–100) with the figure beside it, the rated-meal count
/// as meta, and the change since their earlier meals as a delta Badge (up `primary`,
/// down `warning`, flat `secondary`). Tapping a row calls `onSelectMember`.
struct PartyTasteMatchCard: View {
    let matches: [MemberTasteMatch]
    var onSelectMember: ((MemberTasteMatch) -> Void)? = nil

    var body: some View {
        DSSection("Taste match") {
            if matches.isEmpty {
                // EmptyState README copy for a chart without enough data.
                EmptyState("Not enough meals yet", message: "Taste match needs a few rated meals from each member.")
            } else {
                Card(layout: .list) {
                    ForEach(matches) { row($0) }
                }
            }
        }
    }

    private func row(_ item: MemberTasteMatch) -> some View {
        let trailing: ListRowTrailing? = item.trendDelta.map { ListRowTrailing.badge(Badge.delta($0, size: .sm)) }
        let action: (() -> Void)? = onSelectMember.map { select in { select(item) } }
        return ListRow(
            accessibilityTitle: "\(item.name), \(item.matchScore)% match",
            meta: item.ratedMealsCount == 1 ? "1 rated meal" : "\(item.ratedMealsCount) rated meals",
            leading: .avatar(Avatar(name: item.name, size: .sm, decorative: true)),
            trailing: trailing,
            action: action
        ) {
            VStack(alignment: .leading, spacing: DS.Spacing.s1_5) {
                HStack(spacing: DS.Spacing.s2) {
                    Text(item.name)
                        .textStyle(.sansMd, weight: onSelectMember == nil ? nil : .semibold)
                    Spacer(minLength: DS.Spacing.s2)
                    Text("\(item.matchScore)%")
                        .textStyle(.sansSm, numeric: true)
                }
                Bar(value: Double(item.matchScore), size: .sm, label: "\(item.name)\u{2019}s taste match")
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
    ]) { _ in }
    .padding(DS.Spacing.gutter)
    .background(DS.Color.bg)
}
