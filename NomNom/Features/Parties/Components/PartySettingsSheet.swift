import SwiftUI

/// Sheet for dinner party members to edit settings, toggle public visibility,
/// update about description, view invites, or leave the party.
struct PartySettingsSheet: View {
    let party: Party
    var onPartyLeft: (() -> Void)? = nil

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var about: String = ""
    @State private var isPublic: Bool = false
    @State private var photoData: Data? = nil
    @State private var isPhotoRemoved = false
    @State private var isSaving = false
    @State private var confirmLeave = false
    @State private var resentAlertMessage: String?

    private var invites: [PartyInvite] {
        store.invites(forParty: party.id)
    }

    private var canSave: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.section) {
                    // 1. General Details
                    SectionCard("Party Details") {
                        VStack(alignment: .leading, spacing: 14) {
                            PartyAvatarPicker(
                                partyName: name.isEmpty ? party.name : name,
                                existingPhotoPath: party.photoPath,
                                photoData: $photoData,
                                isRemoved: $isPhotoRemoved,
                                size: 72
                            )
                            .padding(.bottom, 2)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Name")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(DS.Color.textSecondary)
                                TextField("Party name", text: $name)
                                    .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("About")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(DS.Color.textSecondary)
                                TextArea("Describe your dinner party...", text: $about, lineLimit: 3...5)
                            }

                            Divider()

                            Toggle(isOn: $isPublic) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Public Dinner Party")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(DS.Color.textPrimary)
                                    Text("Allows other foodies to find and follow what you're eating.")
                                        .font(.caption)
                                        .foregroundStyle(DS.Color.textSecondary)
                                }
                            }
                            .tint(Color.accentColor)
                        }
                    }

                    // 2. Pending Invites
                    if !invites.isEmpty {
                        invitesSection
                    }

                    // 3. Danger Zone
                    dangerSection
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("Party Settings", displayMode: .inline)
            .sheetCommitToolbar(
                isSaving: isSaving,
                canSave: canSave,
                onCancel: { dismiss() },
                onSave: { saveChanges() }
            )
            .onAppear {
                name = party.name
                about = party.about
                isPublic = party.isPublic
            }
            .alert("Leave Party?", isPresented: $confirmLeave) {
                Button("Leave", role: .destructive) {
                    Task {
                        await store.leaveParty(party)
                        dismiss()
                        onPartyLeft?()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You will lose access to meals served to this party. If you are the last member, the party will be deleted.")
            }
            .alert("Invitation Resent", isPresented: Binding(
                get: { resentAlertMessage != nil },
                set: { if !$0 { resentAlertMessage = nil } }
            )) {
                Button("OK") { resentAlertMessage = nil }
            } message: {
                Text(resentAlertMessage ?? "")
            }
        }
    }

    private var invitesSection: some View {
        SectionCard("Invited") {
            VStack(spacing: 8) {
                ForEach(invites) { invite in
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(DS.Color.textSecondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(invite.inviteeEmail ?? "Invited member")
                                .font(.subheadline)
                                .foregroundStyle(DS.Color.textPrimary)
                            Text(invite.status.rawValue.capitalized)
                                .font(.caption2)
                                .foregroundStyle(invite.status == .pending ? DS.Color.accentText : DS.Color.textSecondary)
                        }

                        Spacer()

                        if invite.isPending {
                            HStack(spacing: 8) {
                                Button("Resend") {
                                    Task {
                                        let success = await store.resendPartyInvite(invite)
                                        if success {
                                            resentAlertMessage = "Invitation resent to \(invite.inviteeEmail ?? "member")."
                                        }
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                Button(role: .destructive) {
                                    Task { await store.revokePartyInvite(invite) }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 2)

                    if invite.id != invites.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private var dangerSection: some View {
        SectionCard {
            Button(role: .destructive) {
                confirmLeave = true
            } label: {
                Label("Leave party", systemImage: "arrow.right.door")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }

    private func saveChanges() {
        guard canSave else { return }
        isSaving = true
        Task {
            await store.updateParty(
                party,
                name: name,
                about: about,
                isPublic: isPublic,
                newPhotoData: photoData,
                removePhoto: isPhotoRemoved
            )
            isSaving = false
            dismiss()
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartySettingsSheet(party: party)
        }
    }
}
