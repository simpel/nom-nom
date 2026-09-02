import SwiftUI

/// Dedicated sheet for managing household eaters who don't have separate accounts.
struct HouseholdMembersSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let emojiChoices = ["🧒", "👦", "👧", "🧑", "👩", "👨", "👶", "🐣", "🦊", "🐻", "🐼", "🦁", "🐧", "🦄"]

    var body: some View {
        NavigationStack {
            List {
                HouseholdMembersSection(emojiChoices: emojiChoices)
            }
            .screenTitle("Household Members", displayMode: .inline)
            .sheetDoneToolbar()
        }
    }
}
