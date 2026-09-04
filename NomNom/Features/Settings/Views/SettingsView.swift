import SwiftUI

typealias EatersView = SettingsView

/// Settings tab/sheet: dinner parties, household members, profile settings, and account management.
struct SettingsView: View {
    @Environment(FoodStore.self) private var store
    @Environment(AuthController.self) private var auth

    @State private var isSeeding = false
    @State private var confirmSignOut = false
    @State private var confirmDelete = false

    private let emojiChoices = ["🧒", "👦", "👧", "🧑", "👩", "👨", "👶", "🐣", "🦊", "🐻", "🐼", "🦁", "🐧", "🦄"]

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.section) {
                partiesSection
                HouseholdMembersSection(emojiChoices: emojiChoices)
                NotificationPreferencesSection()
                ProfileSettingsSection(emojiChoices: emojiChoices, confirmSignOut: $confirmSignOut)
                #if DEBUG
                sampleDataSection
                #endif
                DangerZoneSection(confirmDelete: $confirmDelete)
            }
            .padding(.horizontal, DS.Spacing.screenHorizontal)
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
        .background(DS.Color.bg)
        .navigationTitle("Settings")
        .alert("Sign out?", isPresented: $confirmSignOut) {
            Button("Sign out", role: .destructive) {
                Task { await auth.signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your food log stays on the server and comes back when you sign in again.")
        }
        .alert("Delete your account?", isPresented: $confirmDelete) {
            Button("Delete everything", role: .destructive) {
                Task { await auth.deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes your account, every meal and photo you've logged, and the people you track. It cannot be undone.")
        }
        .alert("Couldn't delete your account",
               isPresented: Binding(get: { auth.errorMessage != nil },
                                    set: { if !$0 { auth.errorMessage = nil } })) {
            Button("OK") { auth.errorMessage = nil }
        } message: {
            Text(auth.errorMessage ?? "")
        }
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
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                    .padding(.vertical, 2)
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
                Button {
                    isSeeding = true
                    Task {
                        await SampleData.populate(store)
                        isSeeding = false
                    }
                } label: {
                    HStack {
                        Text("Fill with sample history")
                            .font(.subheadline.weight(.medium))
                        if isSeeding {
                            Spacer()
                            ProgressView().controlSize(.small)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isSeeding)

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

