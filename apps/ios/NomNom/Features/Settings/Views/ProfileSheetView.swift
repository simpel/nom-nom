import SwiftUI

/// Dedicated sheet forwarding to SettingsView for editing personal profile information and preferences.
struct ProfileSheetView: View {
    var body: some View {
        NavigationStack {
            SettingsView(showsProfileLink: false)
                .sheetCloseToolbar()
        }
        .dsSheet()
    }
}
