import SwiftUI

struct RootTabView: View {
    @Environment(FoodStore.self) private var store
    @Environment(NotificationManager.self) private var notifications
    @State private var navigator = AppNavigator()
    @State private var didApplyLaunchArguments = false
    @State private var activeViewMealID: UUID?
    @State private var activePartyID: UUID?
    @State private var showingInbox = false

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
        .sheet(isPresented: $showingInbox) {
            InboxSheetView()
        }
        .onChange(of: notifications.pendingURL) { _, newURL in
            if let newURL {
                handleIncomingURL(newURL)
                notifications.pendingURL = nil
            }
        }
        .onChange(of: notifications.pendingViewMealID) { _, newID in
            if let newID {
                activeViewMealID = newID
                notifications.pendingViewMealID = nil
            }
        }
        .onAppear {
            // Onboarding ends in the inbox when the viewer joined through an invite.
            if notifications.pendingInbox {
                showingInbox = true
                notifications.pendingInbox = false
            }
            if let pending = notifications.pendingURL {
                handleIncomingURL(pending)
                notifications.pendingURL = nil
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
        // Last, so the sheets above inherit it too.
        .environment(navigator)
        #if DEBUG
        .task { await applyLaunchArguments() }
        #endif
    }
    
    @available(iOS 18.0, *)
    @ViewBuilder
    private var modernTabView: some View {
        let tabView = TabView(selection: $navigator.tab) {
            Tab("Meals", systemImage: "fork.knife", value: AppTab.meals) {
                MealsView()
            }
            .badge(store.awaitingMyRating.count)

            Tab("Parties", systemImage: "person.2", value: AppTab.parties) {
                DinnerPartiesView()
            }

            Tab("Recipes", systemImage: "book.pages", value: AppTab.recipes) {
                RecipesView()
            }
            
            Tab("Insights", systemImage: "chart.bar", value: AppTab.insights) {
                InsightsTabView()
            }

            Tab(value: AppTab.search, role: .search) {
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
        TabView(selection: $navigator.tab) {
            MealsView()
                .tag(AppTab.meals)
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
                .badge(store.awaitingMyRating.count)

            DinnerPartiesView()
                .tag(AppTab.parties)
                .tabItem {
                    Label("Parties", systemImage: "person.2")
                }

            RecipesView()
                .tag(AppTab.recipes)
                .tabItem {
                    Label("Recipes", systemImage: "book.pages")
                }
                
            InsightsTabView()
                .tag(AppTab.insights)
                .tabItem {
                    Label("Insights", systemImage: "chart.bar")
                }

            RecipeSearchView()
                .tag(AppTab.search)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard let link = DeepLink(url: url) else { return }
        navigator.tab = AppTab(rawValue: link.tab) ?? .meals
        switch link {
        case .party(let id): activePartyID = id
        case .partyInvite(let id): openInvite(toParty: id)
        case .viewMeal(let id): activeViewMealID = id
        }
    }

    /// A member goes straight to the party; anyone else gets the invite in their inbox
    /// to accept or decline.
    private func openInvite(toParty partyID: UUID) {
        if store.isMember(of: partyID) {
            activePartyID = partyID
            return
        }
        Task {
            guard await store.requestPartyInvite(partyID: partyID) != nil else { return }
            showingInbox = true
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
        if let tab = config.initialTab.flatMap(AppTab.init(rawValue:)) {
            navigator.tab = tab
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

