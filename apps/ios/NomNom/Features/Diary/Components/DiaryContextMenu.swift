import SwiftUI

typealias PartySwitcherMenu = DiaryContextMenu

/// Compact party switcher menu: switches active party context between "Just me" and
/// available dinner parties. The label is an AppButton `secondary soft sm` capsule.
struct DiaryContextMenu: View {
    @Environment(FoodStore.self) private var store

    var body: some View {
        Menu {
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
        } label: {
            AppButtonLabel(
                store.currentParty?.name ?? "Dinner Party",
                icon: "chevron.down",
                iconPosition: .end,
                variant: .secondary,
                appearance: .soft,
                size: .sm
            )
        }
        .buttonStyle(AppPressableButtonStyle())
        .accessibilityLabel("Switch Dinner Party")
    }
}
