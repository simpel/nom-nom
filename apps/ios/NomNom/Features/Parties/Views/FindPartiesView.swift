import SwiftUI

/// "Find parties" from the Parties tab: the parties you follow, then public parties
/// to follow.
struct FindPartiesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.block) {
                FollowedPartiesSection()
                DiscoverPartiesSection()
            }
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s3)
            .padding(.bottom, DS.Spacing.s11)
        }
        .background(DS.Color.bg)
        .screenTitle("Find parties", displayMode: .inline)
    }
}

#Preview {
    NomNomPreview {
        FindPartiesView()
    }
}
