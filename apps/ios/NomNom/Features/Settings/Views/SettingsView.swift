import SwiftUI

/// Settings tab/sheet: dinner parties, household members, profile settings, and account management.
struct SettingsView: View {
    @Environment(FoodStore.self) private var store

    @State private var isSeeding = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s8) {
                partiesSection
                HouseholdMembersSection()
                NotificationPreferencesSection()
                ProfileSettingsSection()
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

    // MARK: - Dinner Parties Section

    /// A navigation ListRow to the party list; pending invites ride along as a count
    /// Badge (Badge README: "a number or words, never both").
    private var partiesSection: some View {
        let count = store.myParties.count
        let invites = store.pendingPartyInvites.count
        return DSSection("Sharing") {
            Card(layout: .list) {
                NavigationLink {
                    DinnerPartiesView()
                } label: {
                    ListRow(
                        "Dinner parties",
                        meta: count == 0 ? "None yet" : "\(count) \(count == 1 ? "party" : "parties")",
                        trailing: invites > 0
                            ? .badge(Badge("\(invites)", appearance: .solid,
                                           accessibilityLabel: "\(invites) \(invites == 1 ? "invite" : "invites")"))
                            : nil,
                        chevron: true
                    )
                }
                .buttonStyle(ListRowButtonStyle())
            }
            Text("Share meals and taste with friends, family or housemates.")
                .textStyle(.sansSm, tone: .tertiary)
                .padding(.horizontal, DS.Spacing.sectionInset)
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
