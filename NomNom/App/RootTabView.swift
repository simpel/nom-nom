import SwiftUI

struct RootTabView: View {
    @Environment(FoodStore.self) private var store
    @Environment(NotificationManager.self) private var notifications
    @State private var selection = 0
    @State private var didApplyLaunchArguments = false
    @State private var activeRateMealID: UUID?
    @State private var activeViewMealID: UUID?
    @State private var activePartyID: UUID?

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                modernTabView
            } else {
                legacyTabView
            }
        }
        .sheet(item: Binding(
            get: { activeRateMealID.map { RateMealSheetTarget(id: $0) } },
            set: { activeRateMealID = $0?.id }
        )) { target in
            MealRatingSheet(mealID: target.id)
        }
        .sheet(item: Binding(
            get: { activeViewMealID.map { RateMealSheetTarget(id: $0) } },
            set: { activeViewMealID = $0?.id }
        )) { target in
            NavigationStack {
                MealDetailView(mealID: target.id, showCloseButton: true)
            }
        }
        .sheet(item: Binding(
            get: { activePartyID.map { RateMealSheetTarget(id: $0) } },
            set: { activePartyID = $0?.id }
        )) { target in
            NavigationStack {
                PartyDetailView(partyID: target.id, showCloseButton: true)
            }
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
        .onChange(of: notifications.pendingViewMealID) { _, newID in
            if let newID {
                activeViewMealID = newID
                notifications.pendingViewMealID = nil
            }
        }
        .onAppear {
            if let pending = notifications.pendingRateMealID {
                activeRateMealID = pending
                notifications.pendingRateMealID = nil
            }
            if let pending = notifications.pendingViewMealID {
                activeViewMealID = pending
                notifications.pendingViewMealID = nil
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
    
    @available(iOS 18.0, *)
    @ViewBuilder
    private var modernTabView: some View {
        let tabView = TabView(selection: $selection) {
            Tab("Meals", systemImage: "fork.knife", value: 0) {
                MealsView()
            }
            .badge(store.awaitingMyRating.count)

            Tab("Parties", systemImage: "person.2", value: 1) {
                DinnerPartiesView()
            }

            Tab("Recipes", systemImage: "book.pages", value: 2) {
                RecipesView()
            }

            Tab(value: 3, role: .search) {
                RecipeSearchView()
            }
        }

        if #available(iOS 26.0, *) {
            tabView.tabViewSearchActivation(.searchTabSelection)
        } else {
            tabView
        }
    }

    @ViewBuilder
    private var legacyTabView: some View {
        TabView(selection: $selection) {
            MealsView()
                .tag(0)
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
                .badge(store.awaitingMyRating.count)

            DinnerPartiesView()
                .tag(1)
                .tabItem {
                    Label("Parties", systemImage: "person.2")
                }

            RecipesView()
                .tag(2)
                .tabItem {
                    Label("Recipes", systemImage: "book.pages")
                }

            RecipeSearchView()
                .tag(3)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }

        let pathParts = url.pathComponents.filter { $0 != "/" }
        let isUniversalLink = url.host == "www.nomnom.casa" || url.host == "nomnom.casa"
        let hostOrPath = isUniversalLink ? (pathParts.first ?? "") : (url.host ?? "")

        // 1. Party links: /invite?party_id=... or /party?id=... or /party/<uuid>
        if let queryItems = components.queryItems {
            if let partyIDString = queryItems.first(where: { $0.name == "party_id" })?.value ?? (hostOrPath == "party" ? queryItems.first(where: { $0.name == "id" })?.value : nil),
               let uuid = UUID(uuidString: partyIDString) {
                selection = 1
                activePartyID = uuid
                return
            }
        }

        if hostOrPath == "party" {
            for part in pathParts {
                if let uuid = UUID(uuidString: part) {
                    selection = 1
                    activePartyID = uuid
                    return
                }
            }
        }

        // 2. Meal links: /rate-meal?id=... or /invite?meal_id=... or /meal?id=...
        if let queryItems = components.queryItems {
            if let idString = queryItems.first(where: { $0.name == "id" || $0.name == "meal_id" })?.value,
               let uuid = UUID(uuidString: idString) {
                selection = 0
                if hostOrPath == "rate-meal" || hostOrPath == "invite" {
                    activeRateMealID = uuid
                } else {
                    activeViewMealID = uuid
                }
                return
            }
        }

        // 3. /meal/<uuid>/rate or /meal/<uuid>
        for part in pathParts {
            if let uuid = UUID(uuidString: part) {
                selection = 0
                if url.path.contains("rate") {
                    activeRateMealID = uuid
                } else {
                    activeViewMealID = uuid
                }
                return
            }
        }
        
        // 4. nomnom://<uuid> (fallback for legacy meal view)
        if !isUniversalLink, let host = url.host, let uuid = UUID(uuidString: host) {
            selection = 0
            activeViewMealID = uuid
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

