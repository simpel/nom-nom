import SwiftUI

struct RootTabView: View {
    @Environment(FoodStore.self) private var store
    @State private var selection = 0
    @State private var didApplyLaunchArguments = false

    var body: some View {
        TabView(selection: $selection) {
            LogListView()
                .tag(0)
                .tabItem {
                    Label("Log", systemImage: "fork.knife")
                }

            FoodCalendarView()
                .tag(1)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            SuggestionsView()
                .tag(2)
                .tabItem {
                    Label("What to eat", systemImage: "sparkles")
                }

            InboxView()
                .tag(3)
                .tabItem {
                    Label("Inbox", systemImage: "tray")
                }
                .badge(store.unreadCount)
        }
        .alert("Something went wrong",
               isPresented: Binding(get: { store.errorMessage != nil },
                                    set: { if !$0 { store.errorMessage = nil } })) {
            Button("OK") { store.errorMessage = nil }
            Button("Retry") { Task { await store.load() } }
        } message: {
            Text(store.errorMessage ?? "")
        }
        #if DEBUG
        .task { await applyLaunchArguments() }
        #endif
    }

    #if DEBUG
    /// Lets the app be driven from the command line for screenshots and checks:
    ///
    ///     xcrun simctl launch <device> se.joelsanden.nomnom \
    ///         -seed-sample-data -initial-tab 2
    private func applyLaunchArguments() async {
        guard !didApplyLaunchArguments else { return }
        didApplyLaunchArguments = true

        let config = LaunchArgumentsParser.parse()
        if let tab = config.initialTab {
            selection = tab
        }
        if config.seedSampleData {
            await SampleData.populate(store)
        }
        await DevSelfCheck.runIfRequested(store)
    }
    #endif
}
