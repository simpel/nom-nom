import SwiftUI

/// Step 2 of creating or editing a dinner party: members (first) and sharing & visibility (second).
struct PartySetupStepView: View {
    var partyID: UUID? = nil
    let name: String
    let about: String
    let photoDraft: FoodStore.PhotosDraft
    @Binding var isPublic: Bool
    var onCreated: ((Party) -> Void)? = nil
    var onDismiss: () -> Void

    @Environment(FoodStore.self) private var store
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var resentAlertMessage: String?

    private var isEditing: Bool { partyID != nil }
    private var party: Party? { partyID.flatMap { store.party($0) } }
    private var invites: [PartyInvite] {
        guard let partyID else { return [] }
        return store.invites(forParty: partyID)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.section) {
                if let party {
                    PartyInviteLinkCard(party: party)
                }

                if party != nil && !invites.isEmpty {
                    invitesSection
                }

                membersSection

                SectionCard("Sharing & Visibility") {
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("Make dinner party public", isOn: $isPublic)
                            .font(.body.weight(.medium))

                        Text("When enabled, other foodies can discover and follow this dinner party.")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.screenHorizontal)
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
        .background(DS.Color.bg)
        .screenTitle("Party Setup", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isSaving {
                    ProgressView().controlSize(.small)
                } else {
                    Button {
                        save()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isSaving)
        .alert("Couldn't save dinner party",
               isPresented: Binding(get: { errorMessage != nil },
                                    set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
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

    private var membersSection: some View {
        SectionCard("Members") {
            if let party {
                let members = store.members(of: party.id)
                VStack(spacing: 8) {
                    ForEach(members) { member in
                        HStack(spacing: 12) {
                            UserAvatar(profile: member, size: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.shownName)
                                    .font(.body)
                                    .foregroundStyle(DS.Color.textPrimary)
                                Text(member.id == party.createdBy ? "Host" : "Member")
                                    .font(.caption2)
                                    .foregroundStyle(DS.Color.textSecondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 2)

                        if member.id != members.last?.id {
                            Divider()
                        }
                    }
                }
            } else {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(DS.Color.accentSoft)
                            .frame(width: 40, height: 40)
                        Image(systemName: "person.badge.shield.checkmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(DS.Color.accentText)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("You (Host)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DS.Color.textPrimary)

                        Text("You will be able to share invite links and invite friends as soon as this party is created.")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var invitesSection: some View {
        SectionCard("Invited") {
            VStack(spacing: 8) {
                ForEach(invites) { invite in
                    HStack(spacing: 12) {
                        Image(systemName: "envelope")
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

    private func save() {
        let partyName = name.trimmedName
        guard !partyName.isEmpty else { return }
        isSaving = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            if let party {
                let photoData = photoDraft.addedData.first
                let removePhoto = photoDraft.isEmpty && party.photoPath != nil
                await store.updateParty(
                    party,
                    name: partyName,
                    about: about,
                    isPublic: isPublic,
                    newPhotoData: photoData,
                    removePhoto: removePhoto
                )
                isSaving = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onDismiss()
            } else {
                let photoData = photoDraft.addedData.first
                if let newParty = await store.createParty(
                    name: partyName,
                    about: about,
                    isPublic: isPublic,
                    photoData: photoData
                ) {
                    store.currentParty = newParty
                    onCreated?(newParty)
                    isSaving = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onDismiss()
                } else {
                    errorMessage = store.errorMessage ?? "An error occurred creating the party."
                    isSaving = false
                }
            }
        }
    }
}
