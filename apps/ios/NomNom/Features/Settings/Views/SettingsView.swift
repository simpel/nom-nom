import SwiftUI

/// App settings: my profile link, profile fields, notifications, debug tools, and account actions.
struct SettingsView: View {
    var showsProfileLink: Bool = true

    @Environment(FoodStore.self) private var store

    @State private var isSeeding = false

    private var profileName: String {
        let name = store.myProfile?.shownName.trimmingCharacters(in: .whitespaces) ?? ""
        return name.isEmpty ? "My profile" : name
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s8) {
                if showsProfileLink {
                    myProfileSection
                }
                ProfileSettingsSection()
                NotificationPreferencesSection()
                #if DEBUG
                sampleDataSection
                #endif
                AccountActionsSection()
            }
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s5)
            .padding(.bottom, DS.Spacing.s11)
        }
        .background(DS.Color.bg)
        .screenTitle("Settings")
    }

    // MARK: - My Profile Link

    private var myProfileSection: some View {
        Card(layout: .list) {
            NavigationLink {
                PersonDetailView(raterRef: .account(store.userID))
            } label: {
                ListRow(
                    profileName,
                    meta: "View taste profile and history",
                    leading: .avatar(Avatar(
                        name: profileName,
                        photoPath: store.myProfile?.photoPath,
                        size: .sm,
                        decorative: true
                    )),
                    chevron: true
                )
            }
            .buttonStyle(ListRowButtonStyle())
        }
    }

    #if DEBUG
    private var sampleDataSection: some View {
        SectionCard("Debug tools") {
            AppButton(
                "Fill with sample history",
                variant: .secondary,
                appearance: .outline,
                fullWidth: true,
                isLoading: isSeeding
            ) {
                isSeeding = true
                Task {
                    await SampleData.populate(store)
                    isSeeding = false
                }
            }

            Text("Debug builds only — adds a few months of made-up meals so the suggestions have something to work with. Writes to whichever Supabase this build points at.")
                .textStyle(.sansSm, tone: .tertiary)
        }
    }
    #endif
}

#Preview {
    NomNomPreview {
        SettingsView()
    }
}
