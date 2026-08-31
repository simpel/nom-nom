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
        List {
            partiesSection
            HouseholdMembersSection(emojiChoices: emojiChoices)
            ProfileSettingsSection(emojiChoices: emojiChoices, confirmSignOut: $confirmSignOut)
            #if DEBUG
            sampleDataSection
            #endif
            DangerZoneSection(confirmDelete: $confirmDelete)
        }
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
        Section {
            NavigationLink {
                PartyListView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dinner Parties")
                            .font(.body)
                        let count = store.myParties.count
                        Text(count == 0 ? "None yet" : "\(count) \(count == 1 ? "party" : "parties")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !store.pendingPartyInvites.isEmpty {
                        Spacer()
                        Text("\(store.pendingPartyInvites.count) invite")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            }
        } header: {
            Text("Dinner Parties")
        } footer: {
            Text("Share meals and collective taste preferences with friends, family, or roomies.")
        }
    }

    #if DEBUG
    private var sampleDataSection: some View {
        Section {
            Button {
                isSeeding = true
                Task {
                    await SampleData.populate(store)
                    isSeeding = false
                }
            } label: {
                HStack {
                    Text("Fill with sample history")
                    if isSeeding {
                        Spacer()
                        ProgressView().controlSize(.small)
                    }
                }
            }
            .disabled(isSeeding)
        } footer: {
            Text("Debug builds only — adds a few months of made-up meals so the suggestions have something to work with. Writes to whichever Supabase this build points at.")
        }
    }
    #endif
}
