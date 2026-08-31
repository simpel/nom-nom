import SwiftUI

typealias PartySwitcherMenu = DiaryContextMenu

/// Compact party switcher menu: switches active party context between "Just me" and available dinner parties.
struct DiaryContextMenu: View {
    @Environment(FoodStore.self) private var store

    var body: some View {
        Menu {
            Button {
                store.currentParty = nil
            } label: {
                if store.currentParty == nil {
                    Label("Just me", systemImage: "checkmark")
                } else {
                    Text("Just me")
                }
            }

            if !store.myParties.isEmpty {
                Divider()
                ForEach(store.myParties) { party in
                    Button {
                        store.currentParty = party
                    } label: {
                        if store.currentParty?.id == party.id {
                            Label(party.name, systemImage: "checkmark")
                        } else {
                            Text(party.name)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: store.currentParty == nil ? "person.crop.circle" : "person.2.fill")
                Text(store.currentParty?.name ?? "Just me")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(.primary)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.secondary.opacity(0.12))
            .clipShape(Capsule())
        }
        .accessibilityLabel("Switch Dinner Party")
    }
}
