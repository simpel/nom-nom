import SwiftUI

/// Shown after the party step when she joined more than one dinner party: a centred
/// ScreenHeader over a `Card(layout: .list)` of the joined parties. Tapping one
/// finishes onboarding and opens Meals for that party.
struct OnboardingPickPartyStep: View {
    let parties: [Party]
    var pickingID: UUID?
    let onPick: (Party) -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.block) {
            ScreenHeader(
                "Where to first?",
                summary: "You're in \(parties.count) dinner parties. Pick one to open; you can switch any time from the menu.",
                role: .moment
            )
            Card(layout: .list) {
                ForEach(parties) { party in
                    ListRow(
                        party.name,
                        leading: .avatar(Avatar(party: party, size: .sm, decorative: true)),
                        trailing: pickingID == party.id ? .view { ProgressView() } : nil,
                        chevron: pickingID == nil,
                        action: { onPick(party) }
                    )
                }
            }
            .disabled(pickingID != nil)
        }
    }
}
