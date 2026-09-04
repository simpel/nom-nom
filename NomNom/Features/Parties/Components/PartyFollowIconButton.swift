import SwiftUI

/// Minimal circular icon button for following or unfollowing a dinner party.
///
/// Features:
/// - Distinct visual states: `plus` (not following) vs `checkmark` (following)
/// - Fluid symbol replacement transition and haptic feedback
/// - 44×44pt touch target ensuring Apple HIG compliance
struct PartyFollowIconButton: View {
    let party: Party

    @Environment(FoodStore.self) private var store
    @State private var isProcessing = false

    private var isFollowing: Bool {
        store.isFollowing(partyID: party.id)
    }

    var body: some View {
        Button {
            toggleFollow()
        } label: {
            ZStack {
                // Background visual circle (32x32)
                Circle()
                    .fill(isFollowing ? DS.Color.accentSoft : Color(uiColor: .tertiarySystemFill))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isFollowing
                                    ? DS.Color.accentText.opacity(0.15)
                                    : DS.Color.line.opacity(0.3),
                                lineWidth: 0.5
                            )
                    )

                if isProcessing {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Image(systemName: isFollowing ? "checkmark" : "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isFollowing ? DS.Color.accentText : DS.Color.textSecondary)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
        .sensoryFeedback(.impact(weight: .light), trigger: isFollowing)
        .accessibilityLabel(isFollowing ? "Unfollow \(party.name)" : "Follow \(party.name)")
    }

    private func toggleFollow() {
        guard !isProcessing else { return }
        isProcessing = true
        Task {
            await store.toggleFollow(party: party)
            isProcessing = false
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            HStack(spacing: 20) {
                PartyFollowIconButton(party: party)
            }
            .padding()
        }
    }
}
