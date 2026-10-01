import SwiftUI

/// Dedicated sheet for managing household eaters who don't have separate accounts.
struct HouseholdMembersSheet: View {
    @Environment(\.dismiss) private var dismiss


    var body: some View {
        NavigationStack {
            List {
                HouseholdMembersSection()
            }
            .screenTitle("Household Members", displayMode: .inline)
            .sheetCloseToolbar()
        }
    }
}
