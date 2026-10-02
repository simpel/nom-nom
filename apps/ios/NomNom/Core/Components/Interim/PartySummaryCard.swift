// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// Whose party a PartySummaryCard shows.
enum PartySummaryCardMode: Equatable {
    /// The viewer's own party (Home hero, Following): no follow control.
    case mine
    /// Someone else's public party: the trailing slot (a follow control) shows.
    case discover
}

/// One recent meal on a PartySummaryCard.
struct PartySummaryMeal: Identifiable {
    let id: UUID
    let source: PhotoCardSource
    /// Normalised 0–1 average, shown as the verdict Badge.
    var score: Double?
    var title: String
}

/// A party at a glance, on one Card: Avatar `md` + name (`serif-sm`) + meta
/// (`sans-sm` tertiary), the about text (`sans-md` secondary, three lines), the
/// average score (ScoreValue `sm` + meal count over a Bar, "Unrated" when
/// nil) and an optional row of PhotoCard `sm` recent meals with verdicts.
///
/// Wrap it in a NavigationLink to open the party. Named `PartySummaryCard` until
/// `Features/Parties/Components/PartyCard.swift` is replaced in Phase 5.
///
/// ```swift
/// PartySummaryCard(party: party, meta: "Anna, Joel, Sam", score: 0.82, mealCount: 12)
/// PartySummaryCard(party: party, mode: .discover, score: nil, mealCount: 0) { FollowButton(party) }
/// ```
struct PartySummaryCard<Trailing: View>: View {
    let party: Party
    var mode: PartySummaryCardMode
    var meta: String?
    var score: Double?
    var mealCount: Int
    var recentMeals: [PartySummaryMeal]
    @ViewBuilder var trailing: Trailing

    init(
        party: Party,
        mode: PartySummaryCardMode = .mine,
        meta: String? = nil,
        score: Double?,
        mealCount: Int,
        recentMeals: [PartySummaryMeal] = [],
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.party = party
        self.mode = mode
        self.meta = meta
        self.score = score
        self.mealCount = mealCount
        self.recentMeals = recentMeals
        self.trailing = trailing()
    }

    private var mealCountText: String {
        mealCount == 1 ? "1 meal" : "\(mealCount) meals"
    }

    var body: some View {
        Card(spacing: DS.Spacing.s4) {
            header
            if !party.about.isEmpty {
                Text(party.about)
                    .textStyle(.sansMd, tone: .secondary)
                    .lineLimit(3)
            }
            scoreBlock
            if !recentMeals.isEmpty {
                mealsRow
            }
        }
    }

    private var header: some View {
        HStack(spacing: DS.Spacing.s3) {
            Avatar(party: party, size: .md)
            VStack(alignment: .leading, spacing: DS.Spacing.s0_5) {
                Text(party.name).textStyle(.serifSm).lineLimit(1)
                if let meta, !meta.isEmpty {
                    Text(meta).textStyle(.sansSm, tone: .tertiary).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if mode == .discover {
                trailing
            }
        }
    }

    /// ScoreCard `compact`'s content without its own surface (a Card never nests in a Card).
    private var scoreBlock: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s3) {
                ScoreValue(score: score, size: .sm)
                Spacer(minLength: DS.Spacing.s2)
                Text(mealCountText).textStyle(.sansSm, tone: .secondary, numeric: true)
            }
            Bar(value: score.map { $0 * 100 })
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }

    private var mealsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: DS.Spacing.s3) {
                ForEach(recentMeals) { meal in
                    PhotoCard(
                        meal.source,
                        size: .sm,
                        badge: meal.score.map { .score($0) },
                        accessibilityLabel: meal.title
                    )
                }
            }
            .padding(.horizontal, CardSize.md.padding)
        }
        .padding(.horizontal, -CardSize.md.padding)
    }
}

extension PartySummaryCard where Trailing == EmptyView {
    init(
        party: Party,
        mode: PartySummaryCardMode = .mine,
        meta: String? = nil,
        score: Double?,
        mealCount: Int,
        recentMeals: [PartySummaryMeal] = []
    ) {
        self.init(
            party: party, mode: mode, meta: meta, score: score,
            mealCount: mealCount, recentMeals: recentMeals
        ) { EmptyView() }
    }
}

private struct PartySummaryCardGallery: View {
    var body: some View {
        NomNomPreview { store in
            ScrollView {
                VStack(spacing: DS.Spacing.s4) {
                    if let party = store.parties.first {
                        let meals = store.meals(forParty: party.id).prefix(4).map { meal in
                            PartySummaryMeal(
                                id: meal.id, source: .meal(meal),
                                score: store.averageScore(forMeal: meal.id), title: store.dishName(forMeal: meal)
                            )
                        }
                        PartySummaryCard(
                            party: party, meta: "Anna, Joel, Sam", score: 0.82,
                            mealCount: 12, recentMeals: Array(meals)
                        )
                        PartySummaryCard(party: party, mode: .discover, meta: "Hosted by Anna", score: nil, mealCount: 0) {
                            AppButton("Follow", appearance: .soft, size: .sm) {}
                        }
                    }
                }
                .padding(DS.Spacing.gutter)
            }
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { PartySummaryCardGallery() }
#Preview("Dark") { PartySummaryCardGallery().preferredColorScheme(.dark) }
