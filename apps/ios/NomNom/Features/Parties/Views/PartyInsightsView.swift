import SwiftUI

/// "See insights" from Party detail: a ScreenHeader with the party's name, then the
/// party's insights (AI summary, ratings over time, taste match, health, flavours,
/// recipe ideas) on their own screen: a ProView behind a ProGate. PartyInsightsSection owns the
/// gutter so its chart can run edge to edge.
struct PartyInsightsView: View {
    let party: Party

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ProGate(
                "Insights are part of Nom Nom Pro",
                message: "See how \(party.name) eats over time.",
                benefits: [
                    "Ratings over time, member by member",
                    "Taste match, health and flavours",
                    "AI recipe ideas for your next dinner"
                ],
                onDismiss: { dismiss() }
            ) {
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.block) {
                        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                            ProMark()
                            ScreenHeader(party.name)
                        }
                        .padding(.horizontal, DS.Spacing.gutter)

                        PartyInsightsSection(partyID: party.id)
                    }
                    .padding(.top, DS.Spacing.s3)
                    .padding(.bottom, DS.Spacing.s11)
                }
            }
            .proView()
            .screenTitle("Insights", displayMode: .inline)
            .sheetCloseToolbar()
        }
        .dsSheet()
    }
}
