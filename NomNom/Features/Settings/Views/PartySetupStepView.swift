import SwiftUI

/// Step 2 of creating a dinner party: members (first) and sharing & visibility (second).
struct PartySetupStepView: View {
    let name: String
    let about: String
    let photoData: Data?
    @Binding var isPublic: Bool
    var onCreated: ((Party) -> Void)?
    var onDismiss: () -> Void

    @Environment(FoodStore.self) private var store
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.section) {
                // 1. Members (First)
                SectionCard("Members") {
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

                            Text("You can invite family and friends with a shareable invite link once created.")
                                .font(.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                    }
                    .padding(.vertical, 2)
                }

                // 2. Sharing & Visibility (Second)
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
                if isCreating {
                    ProgressView().controlSize(.small)
                } else {
                    Button {
                        create()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .interactiveDismissDisabled(isCreating)
        .alert("Couldn't create dinner party",
               isPresented: Binding(get: { errorMessage != nil },
                                    set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func create() {
        let partyName = name.trimmedName
        guard !partyName.isEmpty else { return }
        isCreating = true
        Task {
            if let newParty = await store.createParty(
                name: partyName,
                about: about,
                isPublic: isPublic,
                photoData: photoData
            ) {
                store.currentParty = newParty
                onCreated?(newParty)
                onDismiss()
            } else {
                errorMessage = store.errorMessage ?? "An error occurred creating the party."
            }
            isCreating = false
        }
    }
}
