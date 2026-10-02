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
        // README "Colour": `primary` is "the main action, active tab, focused field".
        .tint(DS.Color.primary)
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
        .onChange(of: notifications.pendingURL) { _, newURL in
            if let newURL {
                handleIncomingURL(newURL)
                notifications.pendingURL = nil
            }
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
            if let pending = notifications.pendingURL {
                handleIncomingURL(pending)
                notifications.pendingURL = nil
            }
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
    
    private var partyTabTitle: String {
        store.currentParty?.name ?? "Parties"
    }

    @available(iOS 18.0, *)
    @ViewBuilder
    private var modernTabView: some View {
        let tabView = TabView(selection: $selection) {
            Tab("Meals", systemImage: "fork.knife", value: 0) {
                MealsView()
            }
            .badge(store.awaitingMyRating.count)

            Tab(partyTabTitle, systemImage: "person.2", value: 1) {
                DinnerPartiesView()
            }

            Tab("Recipes", systemImage: "book.pages", value: 2) {
                RecipesView()
            }
            
            Tab("Insights", systemImage: "chart.bar", value: 3) {
                InsightsTabView()
            }

            Tab(value: 4, role: .search) {
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
                    Label(partyTabTitle, systemImage: "person.2")
                }

            RecipesView()
                .tag(2)
                .tabItem {
                    Label("Recipes", systemImage: "book.pages")
                }
                
            InsightsTabView()
                .tag(3)
                .tabItem {
                    Label("Insights", systemImage: "chart.bar")
                }

            RecipeSearchView()
                .tag(4)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard let link = DeepLink(url: url) else { return }
        selection = link.tab
        switch link {
        case .party(let id): activePartyID = id
        case .rateMeal(let id): activeRateMealID = id
        case .viewMeal(let id): activeViewMealID = id
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

