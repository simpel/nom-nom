import SwiftUI

typealias EatersView = SettingsView

/// Settings tab/sheet: dinner parties, household members, profile settings, and account management.
struct SettingsView: View {
    @Environment(FoodStore.self) private var store

    @State private var isSeeding = false

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.section) {
                partiesSection
                HouseholdMembersSection()
                NotificationPreferencesSection()
                ProfileSettingsSection()
                #if DEBUG
                sampleDataSection
                #endif
                AccountActionsSection()
            }
            .padding(.horizontal, DS.Spacing.screenHorizontal)
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
        .background(DS.Color.bg)
        .navigationTitle("Settings")
    }

    // MARK: - Dinner Parties Section

    private var partiesSection: some View {
        SectionCard("Dinner Parties") {
            VStack(alignment: .leading, spacing: 10) {
                NavigationLink {
                    PartyListView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.title3)
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dinner Parties")
                                .font(.body.weight(.medium))
                                .foregroundStyle(DS.Color.textPrimary)
                            let count = store.myParties.count
                            Text(count == 0 ? "None yet" : "\(count) \(count == 1 ? "party" : "parties")")
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                        Spacer()
                        if !store.pendingPartyInvites.isEmpty {
                            Text("\(store.pendingPartyInvites.count) invite")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, DS.Spacing.sm)
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                    .padding(.vertical, DS.Spacing.sm)
                }
                .buttonStyle(.plain)

                Text("Share meals and collective taste preferences with friends, family, or roomies.")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.top, 4)
            }
        }
    }

    #if DEBUG
    private var sampleDataSection: some View {
        SectionCard("Debug Tools") {
            VStack(alignment: .leading, spacing: 10) {
                AppButton(
                    "Fill with sample history",
                    variant: .neutral,
                    style: .outlined,
                    size: .md,
                    isFullWidth: true,
                    isPending: isSeeding,
                    disabled: isSeeding
                ) {
                    isSeeding = true
                    Task {
                        await SampleData.populate(store)
                        isSeeding = false
                    }
                }

                Text("Debug builds only — adds a few months of made-up meals so the suggestions have something to work with. Writes to whichever Supabase this build points at.")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
    }
    #endif
}

#Preview {
    NomNomPreview {
        SettingsView()
    }
}

