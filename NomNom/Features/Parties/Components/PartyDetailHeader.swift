import SwiftUI
import PhotosUI

/// Editorial hero header for a dinner party: Arc photo hero header,
/// centered metadata, and about description.
/// When no image exists and the user is a member, displays the interactive "Add Cover Photo" deck.
struct PartyDetailHeader: View {
    let party: Party
    var onSelectPhoto: ((Int) -> Void)? = nil

    @Environment(FoodStore.self) private var store
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var isUploadingPhoto = false

    private var isMember: Bool {
        store.isMember(of: party.id)
    }

    private var members: [Profile] {
        store.members(of: party.id)
    }

    private var followers: [PartyFollower] {
        store.followers(of: party.id)
    }

    private var partyPhotos: [String] {
        guard let p = party.photoPath, !p.isEmpty else { return [] }
        return [p]
    }

    private var subtitle: String {
        var parts: [String] = ["\(members.count) \(members.count == 1 ? "member" : "members")"]
        if followers.count > 0 {
            parts.append("\(followers.count) \(followers.count == 1 ? "follower" : "followers")")
        }
        if !party.isPublic {
            parts.append("Private")
        }
        return parts.joined(separator: " • ")
    }

    var body: some View {
        VStack(spacing: DS.Spacing.xs) {
            if partyPhotos.isEmpty && isMember {
                emptyCoverPhotoSection
            } else {
                ArcHeroHeaderView(
                    photoPaths: partyPhotos,
                    partyName: party.name,
                    title: party.name,
                    subtitle: subtitle,
                    alignment: .center,
                    onSelectPhoto: partyPhotos.isEmpty ? nil : onSelectPhoto
                )
            }

            if !party.about.isEmpty {
                Text(party.about)
                    .font(.inter(.body))
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, DS.Spacing.xs)
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                if let prepared = PhotoTools.prepare(image) {
                    Task {
                        isUploadingPhoto = true
                        await store.updateParty(party, newPhotoData: prepared)
                        isUploadingPhoto = false
                    }
                }
            }
            .ignoresSafeArea()
        }
        .task(id: selectedPickerItems) {
            await handlePickedPhoto()
        }
    }

    private var emptyCoverPhotoSection: some View {
        VStack(alignment: .center, spacing: DS.Spacing.heroInner) {
            VStack(spacing: DS.Spacing.md) {
                EmptyPhotoDeckHeroView(
                    selectedPickerItems: $selectedPickerItems,
                    title: "Add Cover Photo",
                    subtitle: "Tap to choose",
                    maxSelectionCount: 1,
                    onDeckTap: { showCamera = true }
                )
                .frame(height: 228)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

                if CameraPicker.isAvailable || isUploadingPhoto {
                    HStack(spacing: 10) {
                        if CameraPicker.isAvailable {
                            Button {
                                showCamera = true
                            } label: {
                                SubtleCapsuleLabel(title: "Camera", systemImage: "camera")
                            }
                            .buttonStyle(.plain)
                        }

                        if isUploadingPhoto {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 6)

            PageHeader(
                title: party.name,
                subtitle: subtitle,
                alignment: .center
            )
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func handlePickedPhoto() async {
        guard let item = selectedPickerItems.first else { return }
        isUploadingPhoto = true
        defer {
            isUploadingPhoto = false
            selectedPickerItems = []
        }
        if let data = try? await item.loadTransferable(type: Data.self),
           let prepared = PhotoTools.prepare(data) {
            await store.updateParty(party, newPhotoData: prepared)
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartyDetailHeader(party: party)
                .padding()
        }
    }
}

