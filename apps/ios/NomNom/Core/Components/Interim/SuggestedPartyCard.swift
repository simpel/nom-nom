// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// A `discover` PartyCard with the reason it was suggested on one line above it
/// (`sans-sm` secondary, `spacing-2` apart). Without a reason it is the plain card.
///
/// ```swift
/// SuggestedPartyCard(party: party, reason: "Similar to The Friday Feast Club \u{00B7} Italian")
/// ```
struct SuggestedPartyCard: View {
    let party: Party
    var reason: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            if let reason {
                Text(reason)
                    .textStyle(.sansSm, tone: .secondary, lines: 1)
                    .padding(.horizontal, DS.Spacing.s1)
            }
            DinnerPartyCard(party: party)
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            SuggestedPartyCard(party: party, reason: "Similar to The Friday Feast Club \u{00B7} Italian")
                .padding(DS.Spacing.gutter)
        }
    }
}
