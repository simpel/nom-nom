import SwiftUI

/// List of Dinner Parties the user is part of, plus incoming invitations and a creation flow.
struct PartyListView: View {
    @Environment(FoodStore.self) private var store

    @Environment(\.dismiss) private var dismiss

    @State private var showingCreate = false
    @State private var newPartyName = ""
    @State private var isCreating = false

    var body: some View {
        List {
            if !store.pendingPartyInvites.isEmpty {
                pendingInvitesSection
            }

            partiesSection
        }
        .navigationTitle("Dinner Parties")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreate = true
                } label: {
                    Label("New Party", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            NavigationStack {
                Form {
                    Section {
                        TextField("Party Name (e.g. Taco Night)", text: $newPartyName)
                    } header: {
                        Text("Party Name")
                    } footer: {
                        Text("Any member can invite others, and meals can be shared with this party.")
                    }
                }
                .navigationTitle("New Dinner Party")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingCreate = false }
                            .disabled(isCreating)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if isCreating {
                            ProgressView()
                        } else {
                            Button("Create") { create() }
                                .disabled(newPartyName.trimmedName.isEmpty)
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private var pendingInvitesSection: some View {
        Section("Pending Invitations") {
            ForEach(store.pendingPartyInvites) { invite in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        let party = store.party(invite.partyID)
                        Text(party?.name ?? "Dinner Party")
                            .font(.body.weight(.medium))
                        let inviter = store.label(for: .account(invite.inviterID))
                        Text("Invited by \(inviter.emoji) \(inviter.name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Accept") {
                        Task { await store.acceptPartyInvite(invite) }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button("Decline") {
                        Task { await store.declinePartyInvite(invite) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var partiesSection: some View {
        Section {
            if store.myParties.isEmpty {
                ContentUnavailableView {
                    Label("No Dinner Parties", systemImage: "person.2.slash")
                } description: {
                    Text("Create a dinner party to log and share meal ratings with a group.")
                }
            } else {
                ForEach(store.myParties) { party in
                    NavigationLink {
                        PartyDetailView(partyID: party.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.2.fill")
                                .font(.title3)
                                .foregroundStyle(.tint)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(party.name)
                                    .font(.body.weight(.medium))
                                let memberCount = store.members(of: party.id).count
                                Text("\(memberCount) \(memberCount == 1 ? "member" : "members")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        } header: {
            Text("Your Parties")
        } footer: {
            Text("Dinner parties are flat groups: every member is equal and can invite others or leave at any time.")
        }
    }

    private func create() {
        let name = newPartyName.trimmedName
        guard !name.isEmpty else { return }
        isCreating = true
        Task {
            let created = await store.createParty(name: name)
            isCreating = false
            if created != nil {
                newPartyName = ""
                showingCreate = false
            }
        }
    }
}
