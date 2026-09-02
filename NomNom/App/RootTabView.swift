import SwiftUI

struct RootTabView: View {
    @Environment(FoodStore.self) private var store
    @Environment(NotificationManager.self) private var notifications
    @State private var selection = 0
    @State private var didApplyLaunchArguments = false
    @State private var activeRateMealID: UUID?

    var body: some View {
        TabView(selection: $selection) {
            MealsView()
                .tag(0)
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
                .badge(store.awaitingMyRating.count)

            RecipesView()
                .tag(1)
                .tabItem {
                    Label("Recipes", systemImage: "book.pages")
                }

            FoodCalendarView()
                .tag(2)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            SuggestionsView()
                .tag(3)
                .tabItem {
                    Label("What to eat", systemImage: "sparkles")
                }
        }
        .sheet(item: Binding(
            get: { activeRateMealID.map { RateMealSheetTarget(id: $0) } },
            set: { activeRateMealID = $0?.id }
        )) { target in
            MealRatingSheet(mealID: target.id)
        }
        .onOpenURL { url in
            handleIncomingURL(url)
        }
        .onChange(of: notifications.pendingRateMealID) { _, newID in
            if let newID {
                activeRateMealID = newID
                notifications.pendingRateMealID = nil
            }
        }
        .onAppear {
            if let pending = notifications.pendingRateMealID {
                activeRateMealID = pending
                notifications.pendingRateMealID = nil
            }
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

    private func handleIncomingURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }

        // 1. nomnom://rate-meal?id=... or nomnom://invite?meal_id=...
        if let queryItems = components.queryItems {
            if let idString = queryItems.first(where: { $0.name == "id" || $0.name == "meal_id" })?.value,
               let uuid = UUID(uuidString: idString) {
                selection = 0
                activeRateMealID = uuid
                return
            }
        }

        // 2. nomnom://meal/<uuid>/rate or nomnom://meal/<uuid>
        let pathParts = url.pathComponents.filter { $0 != "/" }
        for part in pathParts {
            if let uuid = UUID(uuidString: part) {
                selection = 0
                activeRateMealID = uuid
                return
            }
        }
        if let host = url.host, let uuid = UUID(uuidString: host) {
            selection = 0
            activeRateMealID = uuid
            return
        }
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

private struct RateMealSheetTarget: Identifiable {
    let id: UUID
}

#Preview {
    NomNomPreview(inNavigationStack: false) {
        RootTabView()
    }
}

