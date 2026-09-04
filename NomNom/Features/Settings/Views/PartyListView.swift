import SwiftUI

/// Re-exports DinnerPartiesView for backwards compatibility.
struct PartyListView: View {
    var isSheet: Bool = false

    var body: some View {
        DinnerPartiesView(isSheet: isSheet)
    }
}
