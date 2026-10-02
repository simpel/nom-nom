import SwiftUI

/// "See insights" from Party detail: the party's insights (ratings over time, taste
/// match, health, flavours, recipe ideas) on their own screen, behind ProGate.
struct PartyInsightsView: View {
    let party: Party

    var body: some View {
        ScrollView {
            PartyInsightsSection(partyID: party.id)
                .padding(.horizontal, DS.Spacing.gutter)
                .padding(.top, DS.Spacing.s3)
                .padding(.bottom, DS.Spacing.s11)
        }
        .background(DS.Color.bg)
        .screenTitle("Insights", displayMode: .inline)
    }
}
