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
            Section {
                Menu("Dinner parties", systemImage: "person.2") {
                    if !store.myParties.isEmpty {
                        Picker("Dinner party", selection: partySelection) {
                            ForEach(store.myParties) { party in
                                Text(party.name).tag(Optional(party.id))
                            }
                        }
                        .pickerStyle(.inline)
                    }
                    Button("Manage parties", systemImage: "gearshape") { navigator.tab = .parties }
                }
            }
            Section {
                Button { sheet = .inbox } label: {
                    if store.unreadCount > 0 {
                        Label(store.unreadCount == 1 ? "Inbox (1 unread)" : "Inbox (\(store.unreadCount) unread)", systemImage: "tray")
                    } else {
                        Label("Inbox", systemImage: "tray")
                    }
                }
                Button("My profile", systemImage: "person.crop.circle") { sheet = .profile }
                Button("Settings", systemImage: "gearshape") { sheet = .settings }
            }
            Section {
                if !entitlements.isPro {
                    Button("Get Nom Nom Pro", systemImage: "sparkles") { sheet = .paywall }
                }
                Button("Help & feedback", systemImage: "questionmark.circle") { openURL(Self.helpURL) }
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
        .barItemStyle()
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
