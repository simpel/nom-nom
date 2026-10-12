import SwiftUI

/// Sheet for editing the signed-in person's photo and name.
struct ProfileSheetView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                ProfileSettingsSection()
                    .padding(.horizontal, DS.Spacing.gutter)
                    .padding(.top, DS.Spacing.s5)
                    .padding(.bottom, DS.Spacing.s11)
            }
            .background(DS.Color.bg)
            .screenTitle("Edit profile", displayMode: .inline)
            .sheetCloseToolbar()
        }
        .dsSheet()
    }
}
