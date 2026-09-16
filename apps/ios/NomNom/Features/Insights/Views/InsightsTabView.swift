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
                        insights: insights,
                        healthInsights: store.healthInsights(forParty: selectedPartyID),
                        trendData: store.trendline(forParty: selectedPartyID),
                        memberTrendSeries: store.memberTrendlines(forParty: selectedPartyID),
                        mealsLoggedCount: store.meals(forParty: selectedPartyID).count
                    )
                }
            }
            .navigationTitle("Insights")
            .navigationDestination(for: InsightsRoute.self) { route in
                switch route {
                case .dish(let dishID):
                    RecipeDetailView(dishID: dishID)
                }
            }
            .toolbar {
                if store.myParties.count > 1 {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            ForEach(store.myParties) { party in
                                Button {
                                    selectedPartyID = party.id
                                } label: {
                                    if party.id == selectedPartyID {
                                        Label(party.name, systemImage: "checkmark")
                                    } else {
                                        Text(party.name)
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedParty?.name ?? "Select Party")
                                Image(systemName: "chevron.down")
                            }
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if selectedParty != nil {
                        Button {
                            Task {
                                await loadInsights()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
        .task {
            if selectedPartyID == nil {
                selectedPartyID = store.currentParty?.id
            }
        }
        .task(id: selectedPartyID) {
            await loadInsights()
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

// MARK: - Dashboard View

struct InsightsDashboardView: View {
    let insights: PartyInsights?
    let healthInsights: PartyHealthInsights?
    let trendData: [(date: Date, averageScore: Double)]
    let memberTrendSeries: [MemberTrendSeries]
    let mealsLoggedCount: Int

    @State private var selectedTrend: TrendType = .taste

    enum TrendType {
        case taste
        case health
    }

    @ViewBuilder
    private var trendChart: some View {
        if selectedTrend == .taste {
            PartyTasteTrendChart(totalTrend: trendData, memberSeries: memberTrendSeries)
        } else if let healthTrend = healthInsights?.healthScoreTrend {
            let remapped: [(date: Date, averageScore: Double)] = healthTrend.map {
                (date: $0.date, averageScore: $0.averageHealthScore)
            }
            InsightsTrendChart(trendData: remapped, domain: 1...100, valueFormat: "%.0f")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.section) {

                // 1. Header (AI summary sentence, free) + always-free hook stat
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    PageHeader(
                        title: "Group Insights",
                        subtitle: insights?.summarySentence ?? "Check back later when enough meals have been rated by the party.",
                        alignment: .leading
                    )

                    Text("\(mealsLoggedCount) meal\(mealsLoggedCount == 1 ? "" : "s") logged")
                        .font(.subheadline)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .padding(.top, DS.Spacing.screenTop)
                .padding(.horizontal, DS.Spacing.screenHorizontal)

                // 2-5. Trendline, health metrics, flavor profile, recommendations — Pro,
                // one gate for the whole section so free users see a single unlock prompt.
                ProGate {
                    VStack(alignment: .leading, spacing: DS.Spacing.section) {
                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            HStack {
                                Text("Score over time")
                                    .font(.headline)
                                    .foregroundStyle(DS.Color.textPrimary)

                                Spacer()

                                if healthInsights != nil {
                                    Picker("Trend", selection: $selectedTrend) {
                                        Text("Taste").tag(TrendType.taste)
                                        Text("Health").tag(TrendType.health)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 150)
                                }
                            }
                            .padding(.horizontal, DS.Spacing.screenHorizontal)

                            trendChart
                        }

                        if let health = healthInsights {
                            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                                PartyHealthDistributionCard(distribution: health.healthTierDistribution)

                                PartyHealthStrengthsCard(
                                    topStrengths: health.topStrengths,
                                    topConsiderations: health.topConsiderations
                                )

                                if let macros = health.averageMacros {
                                    AverageMacrosCard(macros: macros)
                                }
                            }
                            .padding(.horizontal, DS.Spacing.screenHorizontal)
                        }

                        if let profile = insights?.foodProfile {
                            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                                Text("Flavor Profile")
                                    .font(.headline)
                                    .foregroundStyle(DS.Color.textPrimary)

                                Text(profile)
                                    .font(.body)
                                    .foregroundStyle(DS.Color.textSecondary)
                            }
                            .padding(.horizontal, DS.Spacing.screenHorizontal)
                        }

                        if let recommendations = insights?.recommendations, !recommendations.isEmpty {
                            InsightsRecommendationsCarousel(recommendations: recommendations)
                                .padding(.horizontal, DS.Spacing.screenHorizontal)
                        }
                    }
                }

                Spacer(minLength: DS.Spacing.section * 2)
            }
        }
    }
}
