import SwiftUI

enum InsightsRoute: Hashable {
    case dish(UUID)
}

struct InsightsTabView: View {
    @Environment(FoodStore.self) private var store

    @State private var selectedPartyID: UUID?
    @State private var insights: PartyInsights?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    private var selectedParty: Party? {
        guard let selectedPartyID else { return nil }
        return store.party(selectedPartyID)
    }

    var body: some View {
        NavigationStack {
            Group {
                if selectedParty == nil {
                    VStack {
                        Text("No Party Selected")
                            .font(.title2.weight(.bold))
                        Text("Please select a dinner party from the Parties tab to view insights.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else if isLoading {
                    ProgressView("Loading Insights...")
                        .controlSize(.large)
                } else if let selectedPartyID {
                    InsightsDashboardView(
                        partyID: selectedPartyID,
                        insights: insights,
                        healthInsights: store.healthInsights(forParty: selectedPartyID),
                        trendData: store.trendline(forParty: selectedPartyID),
                        memberTrendSeries: store.memberTrendlines(forParty: selectedPartyID),
                        partyTasteMatches: store.memberTasteMatches(forParty: selectedPartyID, insights: insights),
                        mealsLoggedCount: store.meals(forParty: selectedPartyID).count
                    )
                }
            }
            .screenTitle(selectedParty?.name ?? "Insights", displayMode: .inline)
            .navigationDestination(for: InsightsRoute.self) { route in
                switch route {
                case .dish(let dishID):
                    RecipeDetailView(dishID: dishID)
                }
            }
            .refreshable {
                await loadInsights()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !store.myParties.isEmpty {
                        Menu {
                            ForEach(store.myParties) { party in
                                Button {
                                    selectedPartyID = party.id
                                    store.currentParty = party
                                } label: {
                                    if party.id == selectedPartyID {
                                        Label(party.name, systemImage: "checkmark")
                                    } else {
                                        Text(party.name)
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "person.2")
                                .fontWeight(.semibold)
                        }
                        .accessibilityLabel("Switch Dinner Party")
                    }
                }
            }
        }
        .task {
            if selectedPartyID == nil {
                selectedPartyID = store.currentParty?.id ?? store.myParties.first?.id
            }
        }
        .task(id: selectedPartyID) {
            await loadInsights()
        }
        .onChange(of: store.currentParty?.id) { _, newID in
            if let newID, newID != selectedPartyID {
                selectedPartyID = newID
            }
        }
    }

    private func loadInsights() async {
        guard let partyID = selectedPartyID else {
            self.insights = nil
            return
        }

        isLoading = true
        do {
            self.insights = try await store.fetchInsights(for: partyID)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}


