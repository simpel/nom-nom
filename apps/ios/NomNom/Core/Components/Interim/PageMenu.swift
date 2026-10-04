// DS-GAP: pending design system
import SwiftUI

/// The "…" page menu in every root and detail screen's top bar (PageMenu artboard on
/// the "Nom Nom iOS" canvas), drawn as a native `Menu` (AppButton README: "context
/// menus … use system buttons"). The artboard fixes the groups and their order:
///
/// 1. `context` — the screen's own actions (Edit / Share / Delete meal), when given.
/// 2. Dinner party — the viewer's parties (every account belongs to one), then "Manage parties".
/// 3. You — Inbox (unread count as the subtitle), My profile, Settings.
/// 4. Pro — Get Nom Nom Pro (hidden once subscribed), Help & feedback.
///
/// The label carries the unread dot (ListRow's unread mark, a `spacing-2` `primary`
/// dot), replacing the old bell.
struct PageMenu<Context: View>: View {
    @ViewBuilder var context: () -> Context

    @Environment(FoodStore.self) private var store
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(AppNavigator.self) private var navigator
    @Environment(\.openURL) private var openURL

    @State private var sheet: PageMenuSheet?

    private static var helpURL: URL { URL(string: "https://www.nomnom.casa/support")! }

    var body: some View {
        Menu {
            context()
            Section("Dinner party") {
                if !store.myParties.isEmpty {
                    Picker("Dinner party", selection: partySelection) {
                        ForEach(store.myParties) { party in
                            Text(party.name).tag(Optional(party.id))
                        }
                    }
                    .pickerStyle(.inline)
                }
                Button("Manage parties") { navigator.tab = .parties }
            }
            Section {
                Button { sheet = .inbox } label: {
                    Text("Inbox")
                    if store.unreadCount > 0 {
                        Text(store.unreadCount == 1 ? "1 unread" : "\(store.unreadCount) unread")
                    }
                }
                Button("My profile") { sheet = .profile }
                Button("Settings") { sheet = .settings }
            }
            Section {
                if !entitlements.isPro {
                    Button { sheet = .paywall } label: {
                        Label("Get Nom Nom Pro", systemImage: "sparkles")
                    }
                }
                Button("Help & feedback") { openURL(Self.helpURL) }
            }
        } label: {
            Image(systemName: "ellipsis")
                .fontWeight(DS.TextStyle.Weight.semibold.fontWeight)
                .overlay(alignment: .topTrailing) {
                    if store.unreadCount > 0 {
                        Circle()
                            .fill(DS.Color.primary)
                            .frame(width: DS.Spacing.s2, height: DS.Spacing.s2)
                            .offset(x: DS.Spacing.s1, y: -DS.Spacing.s1)
                    }
                }
        }
        .accessibilityLabel(store.unreadCount > 0 ? "Page menu, \(store.unreadCount) unread" : "Page menu")
        .sheet(item: $sheet) { sheet in
            PageMenuSheetContent(sheet: sheet)
        }
    }

    private var partySelection: Binding<UUID?> {
        Binding(
            get: { store.currentParty?.id },
            set: { id in
                if let party = id.flatMap({ store.party($0) }), store.currentParty?.id != party.id {
                    store.currentParty = party
                }
            }
        )
    }
}

extension PageMenu where Context == EmptyView {
    init() {
        self.init { EmptyView() }
    }
}
