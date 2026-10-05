import SwiftUI

/// Whose party a PartyCard shows.
enum PartyCardMode: Equatable {
    /// A party the viewer belongs to: its ScoreValue beside the name.
    case mine
    /// A party the viewer has not eaten with: no score, and the join action as a
    /// sibling of the link.
    case discover
}

/// One recent meal on a PartyCard: a photo and its date, no verdict.
struct PartyCardMeal: Identifiable {
    let id: UUID
    let source: PhotoCardSource
    /// What the photo shows, for VoiceOver.
    var title: String
    var date: Date
}

/// A dinner party at a glance (components/PartyCard/README.md), on one Card
/// (`spacing-3` gap, bundle.css `.nn-party-card`):
///
/// - The head and summary are one link into the party (`spacing-2` apart): Avatar `lg`
///   (decorative, the name is beside it), the name and the "N members · meta" line,
///   and in `mine` mode a ScoreValue `xs`. The summary is `sans-sm` secondary, two lines.
/// - Recent meals, newest first, are a Timeline `mini`: square thumbnail and date.
/// - `discover`: the `join` control sits under the card's link, never inside it.
///
/// ```swift
/// PartyCard(party: party, score: 0.82, memberCount: 6, meta: "12 meals", recentMeals: meals) {
///     PartyDetailView(partyID: party.id)
/// }
/// PartyCard(party: party, mode: .discover, memberCount: 12) { PartyDetailView(partyID: party.id) } join: {
///     PartyFollowButton(party: party)
/// }
/// ```
struct PartyCard<Destination: View, Join: View>: View {
    let party: Party
    var mode: PartyCardMode
    var score: Double?
    var memberCount: Int?
    var meta: String?
    var recentMeals: [PartyCardMeal]
    private let destination: () -> Destination
    private let join: Join

    init(
        party: Party,
        mode: PartyCardMode = .mine,
        score: Double? = nil,
        memberCount: Int? = nil,
        meta: String? = nil,
        recentMeals: [PartyCardMeal] = [],
        @ViewBuilder destination: @escaping () -> Destination,
        @ViewBuilder join: () -> Join
    ) {
        self.party = party
        self.mode = mode
        self.score = score
        self.memberCount = memberCount
        self.meta = meta
        self.recentMeals = recentMeals
        self.destination = destination
        self.join = join()
    }

    private var metaLine: String {
        let members = memberCount.map { $0 == 1 ? "1 member" : "\($0) members" }
        return [members, meta].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " \u{00B7} ")
    }

    var body: some View {
        Card(spacing: DS.Spacing.s3) {
            ZStack(alignment: .topTrailing) {
                NavigationLink(destination: destination) { main }
                    .buttonStyle(AppPressableButtonStyle())
                
                if mode == .discover {
                    join
                }
            }
            
            if !recentMeals.isEmpty {
                mealsRow
            }
        }
    }

    /// bundle.css `.nn-party-card__main` (gap `spacing-2`), `__head` (gap `spacing-3`)
    /// and `__id` (gap `spacing-0.5`).
    private var main: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            HStack(spacing: DS.Spacing.s3) {
                Avatar(party: party, size: .lg, decorative: true)
                VStack(alignment: .leading, spacing: DS.Spacing.s0_5) {
                    Text(party.name).textStyle(.serifSm, lines: 1)
                    if !metaLine.isEmpty {
                        Text(metaLine).textStyle(.sansSm, tone: .tertiary, lines: 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if mode == .mine {
                    ScoreValue(score: score, size: .xs)
                } else if mode == .discover {
                    // Reserve space for the top-trailing join button so text doesn't overlap
                    Spacer().frame(width: DS.Spacing.s11, height: DS.Spacing.s11)
                }
            }
            if !party.about.isEmpty {
                Text(party.about).textStyle(.sansSm, tone: .secondary, lines: 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    /// README: "rendered as a Timeline `mini`"; the rail bleeds off the card's right edge.
    private var mealsRow: some View {
        Timeline(
            occasions: recentMeals.map { TimelineOccasion(id: AnyHashable($0.id), date: $0.date, photo: $0.source) },
            size: .mini,
            bleed: CardSize.md.padding
        )
    }
}

extension PartyCard where Join == EmptyView {
    init(
        party: Party,
        mode: PartyCardMode = .mine,
        score: Double? = nil,
        memberCount: Int? = nil,
        meta: String? = nil,
        recentMeals: [PartyCardMeal] = [],
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.init(
            party: party, mode: mode, score: score, memberCount: memberCount, meta: meta,
            recentMeals: recentMeals, destination: destination
        ) { EmptyView() }
    }
}

private struct PartyCardGallery: View {
    var body: some View {
        NomNomPreview { store in
            ScrollView {
                VStack(spacing: DS.Spacing.s4) {
                    if let party = store.parties.first {
                        let meals = store.meals(forParty: party.id).prefix(4).map { meal in
                            PartyCardMeal(id: meal.id, source: .meal(meal), title: store.dishName(forMeal: meal), date: meal.eatenOn)
                        }
                        PartyCard(party: party, score: 0.82, memberCount: 4, meta: "12 meals", recentMeals: Array(meals)) {
                            Text(party.name)
                        }
                        PartyCard(party: party, mode: .discover, memberCount: 12) {
                            Text(party.name)
                        } join: {
                            AppButton("Follow", variant: .secondary, appearance: .soft, size: .sm) {}
                        }
                    }
                }
                .padding(DS.Spacing.gutter)
            }
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { PartyCardGallery() }
#Preview("Dark") { PartyCardGallery().preferredColorScheme(.dark) }
